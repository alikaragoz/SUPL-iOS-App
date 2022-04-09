import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol MiniBrowserViewModelInputs {
  // call to set the url
  func configureWith(_ url: URL)

  // call the notify the loading finished
  func webViewDidFinishLoading()

  // call when the cover button is pressed
  func coverButtonPressed()
}

public protocol MiniBrowserViewModelOutputs {
  // emits when the url text is ready
  var urlText: Observable<String> { get }

  // emits when the web view needs to be loaded
  var loadWebViewWithUrl: Observable<URL> { get }

  // emits whether the spinner should be visible
  var setSpinnerState: Observable<Bool> { get }

  // emits whether the webview should be visible
  var setWebViewState: Observable<Bool> { get }

  // emits when the cover button is pressed
  var shouldNotifyCoverPressed: Observable<Void> { get }
}

public protocol MiniBrowserViewModelType {
  var inputs: MiniBrowserViewModelInputs { get }
  var outputs: MiniBrowserViewModelOutputs { get }
}

public final class MiniBrowserViewModel: MiniBrowserViewModelType,
  MiniBrowserViewModelInputs,
MiniBrowserViewModelOutputs {

  public var inputs: MiniBrowserViewModelInputs { return self }
  public var outputs: MiniBrowserViewModelOutputs { return self }

  public init() {
    urlText = configureWithURLProperty
      .unwrap()
      .map { $0.absoluteString }

    loadWebViewWithUrl = configureWithURLProperty.unwrap()
    setSpinnerState = webViewDidFinishLoadingProperty.map { _ in false }.startWith(true)
    setWebViewState = setSpinnerState.map { !$0 }
    shouldNotifyCoverPressed = coverButtonPressedProperty
  }

  // MARK: - Inputs

  private let configureWithURLProperty = BehaviorRelay<URL?>(value: nil)
  public func configureWith(_ url: URL) {
    self.configureWithURLProperty.accept(url)
  }

  private let webViewDidFinishLoadingProperty = PublishSubject<Void>()
  public func webViewDidFinishLoading() {
    self.webViewDidFinishLoadingProperty.onNext(())
  }

  private let coverButtonPressedProperty = PublishSubject<Void>()
  public func coverButtonPressed() {
    coverButtonPressedProperty.onNext(())
  }

  // MARK: - Outputs

  public var urlText: Observable<String>
  public var loadWebViewWithUrl: Observable<URL>
  public var setSpinnerState: Observable<Bool>
  public var setWebViewState: Observable<Bool>
  public var shouldNotifyCoverPressed: Observable<Void>
}
