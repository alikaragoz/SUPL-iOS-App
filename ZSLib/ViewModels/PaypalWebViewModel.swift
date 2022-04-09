import Alamofire
import Foundation
import RxSwift
import RxCocoa
import ZSAPI
import WebKit

private enum PaypalWebViewError: Error, LocalizedError {
  case urlError
  case cantConvertSentryJSONToObject

  public var errorDescription: String? {
    switch self {
    case .urlError: return "urlError"
    case .cantConvertSentryJSONToObject: return "cantConvertSentryJSONToObject"
    }
  }
}

public protocol PaypalWebViewModelInputs {
  // call to configure with an url
  func configureWith(url: URL?)

  // call when the view did appear
  func viewDidAppear()

  // call when the previously loaded url did finish
  func didFinishLoadingCurrentUrl()

  // call when the decidePolicy delegate of the WKWebView is called
  func decidePolicyFor(navigationAction: WKNavigationAction,
                       decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)

  // call when a js message is received
  func didReceiveMessage(_ message: WKScriptMessage)

  // call when the done button is pressed
  func doneButtonPressed()
}

public protocol PaypalWebViewModelOutputs {
  // emits when the view did finish doing it's thing
  var didFinish: Observable<PaypalCredentials> { get }

  // emits when the view should be dismissed
  var shouldDismiss: Observable<Void> { get }

  // emits when the webview needs to evaluate some JS
  var shouldEvaluateJS: Observable<String> { get }

  // emits when the webview should load a specific url
  var shouldLoadUrl: Observable<URL> { get }

  // emits wheter the overlay should be shown
  var shouldShowOverlay: Observable<Bool> { get }

  // emits the progress of the paypal login
  var progress: Observable<Float> { get }
}

public protocol PaypalWebViewModelType {
  var inputs: PaypalWebViewModelInputs { get }
  var outputs: PaypalWebViewModelOutputs { get }
}

public final class PaypalWebViewModel: PaypalWebViewModelType,
  PaypalWebViewModelInputs,
PaypalWebViewModelOutputs {

  public var inputs: PaypalWebViewModelInputs { return self }
  public var outputs: PaypalWebViewModelOutputs { return self }

  private let disposeBag = DisposeBag()

  public enum JSFunction: String, Equatable, CaseIterable {
    case onCredentials
    case onProgress
    case onSentryError
  }

  public enum Page: String, Equatable {
    case create = "developer/applications/create"
    case welcome = "consumerOnBoarding"

    func matchesUrl(_ url: URL) -> Bool {
      return url.absoluteString.contains(self.rawValue)
    }

    static func pageForUrl(_ url: URL) -> Page? {
      if Page.create.matchesUrl(url) {
        return .create
      } else if Page.welcome.matchesUrl(url) {
        return .welcome
      }
      return nil
    }
  }

  public init() {
    let willLoadUrl = decidePolicyForProperty
      .map { $0.0.request.url }
      .unwrap()
      .share(replay: 1)

    decidePolicyForProperty
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: {
        $0.1(.allow)
      })
      .disposed(by: disposeBag)

    let didLoadUrl = didFinishLoadingCurrentUrlProperty
      .withLatestFrom(willLoadUrl)
      .share(replay: 1)

    let shouldLoadCreateAppUrl = willLoadUrl
      .map(Page.pageForUrl)
      .filter { $0 == .welcome }
      .map { _ in
        return URL(string: "https://developer.paypal.com/developer/applications/create")
      }
      .share(replay: 1)

    shouldEvaluateJS = didLoadUrl
      .map(Page.pageForUrl)
      .filter { $0 == .create }
      .flatMap { _ in getPaypalJS() }
      .retry(3)

    shouldLoadUrl = Observable
      .merge(urlProperty.asObservable(), shouldLoadCreateAppUrl)
      .unwrap()

    shouldDismiss = doneButtonPressedProperty

    progress = didReceiveMessageProperty
      .filter { $0.name == JSFunction.onProgress.rawValue }
      .map { message in
        guard let progress = message.body as? Double else {
          return 0
        }
        return Float(progress)
    }

    shouldShowOverlay = willLoadUrl
      .map {
        if Page.pageForUrl($0) == .create {
          return true
        } else {
          return nil
        }
      }
      .unwrap()
      .startWith(false)

    didFinish = didReceiveMessageProperty
      .filter { $0.name == JSFunction.onCredentials.rawValue }
      .map {
        guard
          let json = $0.body as? String,
          let data = json.data(using: .utf8),
          let paypalCredentials = try? JSONDecoder().decode(PaypalCredentials.self, from: data) else {
            return nil
        }
        return paypalCredentials
      }
      .delay(1, scheduler: AppEnvironment.current.mainScheduler)
      .unwrap()

    let onSentryError: Observable<SentryRequest> = didReceiveMessageProperty
      .filter { $0.name == JSFunction.onSentryError.rawValue }
      .map {
        guard
          let string = $0.body as? String,
          let data = string.data(using: .utf8),
          let sentryRequest = try? JSONDecoder().decode(SentryRequest.self, from: data)
          else {
            throw PaypalWebViewError.cantConvertSentryJSONToObject
        }
        AppEnvironment.current.analytics.trackErroredPaypalLogin(error: string)
        return sentryRequest
      }

    onSentryError
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { submitSentry(request: $0) })
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let urlProperty = BehaviorRelay<URL?>(value: nil)
  public func configureWith(url: URL?) {
    self.urlProperty.accept(url)
  }

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  private let doneButtonPressedProperty = PublishSubject<Void>()
  public func doneButtonPressed() {
    self.doneButtonPressedProperty.onNext(())
  }

  private let didFinishLoadingCurrentUrlProperty = PublishSubject<Void>()
  public func didFinishLoadingCurrentUrl() {
    self.didFinishLoadingCurrentUrlProperty.onNext(())
  }

  private typealias DecisionHandler = (WKNavigationActionPolicy) -> Void
  private let decidePolicyForProperty = PublishSubject<(WKNavigationAction, DecisionHandler)>()
  public func decidePolicyFor(navigationAction: WKNavigationAction,
                              decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    self.decidePolicyForProperty.onNext((navigationAction, decisionHandler))
  }

  private let didReceiveMessageProperty = PublishSubject<WKScriptMessage>()
  public func didReceiveMessage(_ message: WKScriptMessage) {
    self.didReceiveMessageProperty.onNext(message)
  }

  // MARK: - Outputs

  public var didFinish: Observable<PaypalCredentials>
  public var shouldDismiss: Observable<Void>
  public var shouldEvaluateJS: Observable<String>
  public var shouldLoadUrl: Observable<URL>
  public var shouldShowOverlay: Observable<Bool>
  public var progress: Observable<Float>
}

private func getPaypalJS() -> Observable<String> {
  guard let url = URL(string: "https://static.supl.co/paypal_link.js") else {
    return .error(PaypalWebViewError.urlError)
  }

  return SessionManager.default.rx
    .request(.get, url)
    .autoRetryOnNetworkError()
    .validate(statusCode: 200..<300)
    .string()
}

// MARK: - Sentry

private struct SentryRequest: Codable {
  let url: URL
  let body: String
}

private func submitSentry(request: SentryRequest) {
  guard
    let data = request.body.data(using: .utf8),
    let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
    else {
      trackRuntimeError("Can't convert string to json")
      return
  }

  _ = SessionManager.default.rx.request(
    .post,
    request.url,
    parameters: json,
    encoding: JSONEncoding.default,
    headers: ["Content-type": "application/json"]
    )
    .autoRetryOnNetworkError()
    .map {
      return $0
    }
    .validate(statusCode: 200..<300)
    .subscribe()
}
