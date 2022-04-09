import Foundation
import Intercom
import RxSwift
import RxCocoa
import ZSAPI
import Crashlytics

private enum PaypalComponentViewModelError: Error, LocalizedError {
  case cantGetUserDict

  public var errorDescription: String? {
    switch self {
    case .cantGetUserDict: return "cantGetUserDict"
    }
  }
}

public protocol PaypalComponentViewModelInputs {
  // call to configure with a shop
  func configureWith(shop: Shop)
  
  // call when the webview finished with a paypal credentials
  func paypalWebViewDidFinishWithPaypalCredentials(_ paypalCredentials: PaypalCredentials)
  
  // call then the web view did dismiss
  func paypalWebViewDidDismiss()
}

public protocol PaypalComponentViewModelOutputs {
  // emits when the paypal webview should be dismissed
  var shouldDismissPaypalWebView: Observable<Void> { get }
  
  // emits when the paypal connect fails
  var paypalConnectDidFail: Observable<Error> { get }
  
  // emits when the paypal connect succeeds
  var paypalConnectDidSucceed: Observable<Void> { get }
}

public protocol PaypalComponentViewModelType {
  var inputs: PaypalComponentViewModelInputs { get }
  var outputs: PaypalComponentViewModelOutputs { get }
}

public final class PaypalComponentViewModel: PaypalComponentViewModelType,
  PaypalComponentViewModelInputs,
PaypalComponentViewModelOutputs {
  
  public var inputs: PaypalComponentViewModelInputs { return self }
  public var outputs: PaypalComponentViewModelOutputs { return self }
  
  private let disposeBag = DisposeBag()
  
  public init() {
    
    let paypalResultSuccess = PublishSubject<Void>()
    let paypalResultError = PublishSubject<Error>()
    let shop = configureProperty.unwrap().take(1)
    
    paypalWebViewDidFinishWithPaypalCredentials
      .withLatestFrom(
        Observable.combineLatest(paypalWebViewDidFinishWithPaypalCredentials, shop)
      )
      .flatMap {
        handleLogin(paypalCredentials: $0.0, shop: $0.1)
      }
      .catchErrorAndContinue(handler: {
        paypalResultError.onNext($0)
        AppEnvironment.current.analytics.trackErroredPaypalLogin(error: $0.localizedDescription)
      })
      .subscribe(onNext: { _ in
        paypalResultSuccess.onNext(())
        AppEnvironment.current.analytics.trackSucceededPaypalLogin()
      })
      .disposed(by: disposeBag)
    
    paypalConnectDidSucceed = paypalResultSuccess
    paypalConnectDidFail = paypalResultError
    
    shouldDismissPaypalWebView = Observable.merge(
      paypalWebViewDidDismissProp,
      paypalConnectDidFail.map { _ in () },
      paypalConnectDidSucceed.map { _ in () }
    )
  }
  
  // MARK: - Inputs
  
  private let configureProperty = BehaviorRelay<Shop?>(value: nil)
  public func configureWith(shop: Shop) {
    configureProperty.accept(shop)
  }
  
  private let paypalWebViewDidFinishWithPaypalCredentials = PublishSubject<PaypalCredentials>()
  public func paypalWebViewDidFinishWithPaypalCredentials(_ paypalCredentials: PaypalCredentials) {
    self.paypalWebViewDidFinishWithPaypalCredentials.onNext(paypalCredentials)
  }
  
  private let paypalWebViewDidDismissProp = PublishSubject<Void>()
  public func paypalWebViewDidDismiss() {
    self.paypalWebViewDidDismissProp.onNext(())
  }
  
  // MARK: - Outputs
  
  public var paypalConnectDidSucceed: Observable<Void>
  public var shouldDismissPaypalWebView: Observable<Void>
  public var paypalConnectDidFail: Observable<Error>
}

private func handleLogin(paypalCredentials: PaypalCredentials, shop: Shop) -> Observable<Void> {
  
  let paypalClient = AppEnvironment.current.mainBundle.isLocal
    ? paypalCredentials.sandbox
    : paypalCredentials.live

  guard let userParams = paypalCredentials.user.dictionary else {
    return .error(PaypalComponentViewModelError.cantGetUserDict)
  }

  var params: [String: Any] = [:]
  params["client_id"] = paypalClient.id
  params["secret"] = paypalClient.secret
  params["user"] = userParams

  return AppEnvironment.current.apiService
    .loginWithPaypal(params: params)
    .autoRetryOnNetworkError()
    .map {
      AppEnvironment.login($0)
      if let userId = $0.user {
        AppEnvironment.current.analytics.set(paypalUser: paypalCredentials.user)
        AppEnvironment.current.analytics.set(userId: userId)
        AppEnvironment.current.userDefaults.paypalUser = paypalCredentials.user

        if AppEnvironment.current.mainBundle.isRelease {
          let user = paypalCredentials.user
          Crashlytics.sharedInstance().setUserEmail(user.email)
          Crashlytics.sharedInstance().setUserName("\(user.firstName) \(user.lastName)")
          Crashlytics.sharedInstance().setUserIdentifier(userId)

          Intercom.registerUser(withEmail: user.email)
          let userAttr = ICMUserAttributes()
          userAttr.name = [user.firstName, user.lastName].joined(separator: " ")
          userAttr.email = user.email
          Intercom.updateUser(userAttr)
        }
      }
      return ()
    }
    .flatMap {
      AppEnvironment.current.apiService.assignUser(shopId: shop.id)
    }
    .autoRetryOnNetworkError()
}
