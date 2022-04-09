import Foundation
import FBSDKCoreKit
import ZSPrelude
import ZSAPI
import RxSwift
import RxCocoa
import UserNotifications

public enum NotificationAuthorizationStatus {
  case authorized
  case denied
  case notDetermined
  @available(iOS 12, *)
  case provisional
}

public protocol AppDelegateViewModelInputs {
  // call when the application finishes launching
  func applicationDidFinishLaunching(application: UIApplication?, launchOptions: [AnyHashable: Any]?)

  // Call to open a url that was sent to the app
  func applicationOpenUrl(application: UIApplication?,
                          url: URL,
                          sourceApplication: String?,
                          annotation: Any) -> Bool

  // call when the application will enter foreground
  func applicationDidBecomeActive()

  // call when the application will enter foreground
  func applicationWillEnterForeground()

  // call when the application enters background
  func applicationDidEnterBackground()

  // call when the crash manager did finish sending crash report
  func crashlyticsDidDetectReport()

  // call when the app delegate gets notice of a successful notification registration
  func didRegisterForRemoteNotifications(withDeviceTokenData data: Data)

  // call when the app asks for remote notification registration
  func requestRegisterForRemoteNotifications()

  // call when notification authorization is completed with user permission or denial
  func notificationAuthorizationCompleted(isGranted: Bool)

  // call when notification authorization status received.
  func notificationAuthorizationStatusReceived(_ authorizationStatus: UNAuthorizationStatus)
}

public protocol AppDelegateViewModelOutputs {
  // emits when the application should configure Fabric
  var configureFabric: Observable<Void> { get }

  // emits when the application should configure Intercome
  var configureIntercom: Observable<Void> { get }

  // emits when the hool needs to me configured
  var configureRxHook: Observable<Void> { get }

  // return this value in the delegate method.
  var facebookOpenURLReturnValue: BehaviorRelay<Bool> { get }

  // emits when we should register for remote notifications
  var registerForRemoteNotifications: Observable<Void> { get }

  // emits when the token should be sent to intercom
  var shouldSendDeviceTokenToIntercom: Observable<Data> { get }

  // emits when application should request authorizatoin for notifications
  var authorizeForRemoteNotifications: Observable<Void> { get }

  // Emits when application should call getNotificationSettings() to obtain authorization status
  var getNotificationAuthorizationStatus: Observable<Void> { get }
}

public protocol AppDelegateViewModelType {
  var inputs: AppDelegateViewModelInputs { get }
  var outputs: AppDelegateViewModelOutputs { get }
}

public class AppDelegateViewModel: AppDelegateViewModelType,
  AppDelegateViewModelInputs,
AppDelegateViewModelOutputs {

  public var inputs: AppDelegateViewModelInputs { return self }
  public var outputs: AppDelegateViewModelOutputs { return self }

  private let disposeBag = DisposeBag()

  public init() {
    configureFabric = applicationLaunchOptionsProperty
      .map { _ in
        if AppEnvironment.current.mainBundle.isRelease { return () }
        return nil
      }
      .unwrap()

    configureIntercom = applicationLaunchOptionsProperty
      .map { _ in () }

    configureRxHook = applicationLaunchOptionsProperty
      .map { _ in return () }

    registerForRemoteNotifications = notificationAuthorizationCompletedProperty
      .filter(isTrue)
      .map { _ in return () }

    let applicationIsReadyForRegisteringNotifications = Observable.merge(
      applicationWillEnterForegroundProperty,
      applicationLaunchOptionsProperty.map { _ in return () },
      requestRegisterForRemoteNotificationsProperty
    )

    getNotificationAuthorizationStatus = applicationIsReadyForRegisteringNotifications
    authorizeForRemoteNotifications = requestRegisterForRemoteNotificationsProperty
    shouldSendDeviceTokenToIntercom = deviceTokenDataProperty

    Observable
      .merge(applicationLaunchOptionsProperty.map { _ in () }, applicationWillEnterForegroundProperty)
      .subscribe { _ in AppEnvironment.current.analytics.trackOpenedApp() }
      .disposed(by: disposeBag)

    applicationLaunchOptionsProperty.take(1).subscribe(onNext: { options in
      _ = AppEnvironment.current.facebookAppDelegate.application(
        options.application,
        didFinishLaunchingWithOptions: options.options
      )
    }).disposed(by: disposeBag)

    let openUrl = self.applicationOpenUrlProperty.unwrap()
    let facebookOpenURLReturnValue = self.facebookOpenURLReturnValue

    openUrl.subscribe(onNext: {
      let app = AppEnvironment.current.facebookAppDelegate.application(
        $0.application, open: $0.url, sourceApplication: $0.sourceApplication, annotation: $0.annotation
      )
      facebookOpenURLReturnValue.accept(app)
    }).disposed(by: disposeBag)

    applicationDidBecomeActiveProperty
      .subscribe { _ in
        FBSDKAppEvents.activateApp()
      }
      .disposed(by: disposeBag)

    applicationDidEnterBackgroundProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackClosedApp() }
      .disposed(by: disposeBag)

    crashlyticsDidDetectReportProp
      .subscribe { _ in AppEnvironment.current.analytics.trackCrashedApp() }
      .disposed(by: disposeBag)

    notificationAuthorizationStatusProperty
      .unwrap()
      .skipUntil(notificationAuthorizationCompletedProperty.map { _ in return () })
      .take(1)
      .subscribe(onNext: {  status in
        switch status {
        case .authorized:
          AppEnvironment.current.analytics.trackPushPermissionOptIn()
        case .denied:
          AppEnvironment.current.analytics.trackPushPermissionOptOut()
        case .notDetermined, .provisional: ()
        }
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private typealias ApplicationWithOptions = (application: UIApplication?, options: [AnyHashable: Any]?)
  private let applicationLaunchOptionsProperty = PublishSubject<ApplicationWithOptions>()
  public func applicationDidFinishLaunching(application: UIApplication?, launchOptions: [AnyHashable: Any]?) {
    self.applicationLaunchOptionsProperty.onNext((application, launchOptions))
  }

  fileprivate typealias ApplicationOpenUrl = (
    application: UIApplication?,
    url: URL,
    sourceApplication: String?,
    annotation: Any
  )
  fileprivate let applicationOpenUrlProperty = BehaviorRelay<ApplicationOpenUrl?>(value: nil)
  public func applicationOpenUrl(application: UIApplication?,
                                 url: URL,
                                 sourceApplication: String?,
                                 annotation: Any) -> Bool {
    self.applicationOpenUrlProperty.accept((application, url, sourceApplication, annotation))
    return self.facebookOpenURLReturnValue.value
  }

  private let applicationDidBecomeActiveProperty = PublishSubject<Void>()
  public func applicationDidBecomeActive() {
    self.applicationDidBecomeActiveProperty.onNext(())
  }

  private let applicationWillEnterForegroundProperty = PublishSubject<Void>()
  public func applicationWillEnterForeground() {
    self.applicationWillEnterForegroundProperty.onNext(())
  }

  private let applicationDidEnterBackgroundProperty = PublishSubject<Void>()
  public func applicationDidEnterBackground() {
    self.applicationDidEnterBackgroundProperty.onNext(())
  }

  private let crashlyticsDidDetectReportProp = PublishSubject<Void>()
  public func crashlyticsDidDetectReport() {
    self.crashlyticsDidDetectReportProp.onNext(())
  }

  private let deviceTokenDataProperty = PublishSubject<Data>()
  public func didRegisterForRemoteNotifications(withDeviceTokenData data: Data) {
    self.deviceTokenDataProperty.onNext(data)
  }

  private let requestRegisterForRemoteNotificationsProperty = PublishSubject<Void>()
  public func requestRegisterForRemoteNotifications() {
    self.requestRegisterForRemoteNotificationsProperty.onNext(())
  }

  fileprivate let notificationAuthorizationCompletedProperty = PublishSubject<Bool>()
  public func notificationAuthorizationCompleted(isGranted: Bool) {
    self.notificationAuthorizationCompletedProperty.onNext(isGranted)
  }

  fileprivate let notificationAuthorizationStatusProperty =
    PublishSubject<NotificationAuthorizationStatus?>()
  public func notificationAuthorizationStatusReceived(_ authorizationStatus: UNAuthorizationStatus) {
    return self.notificationAuthorizationStatusProperty.onNext(authStatusType(for: authorizationStatus))
  }

  // MARK: - Outputs

  public var configureFabric: Observable<Void>
  public var configureIntercom: Observable<Void>
  public var configureRxHook: Observable<Void>
  public var facebookOpenURLReturnValue = BehaviorRelay<Bool>(value: false)
  public var registerForRemoteNotifications: Observable<Void>
  public var shouldSendDeviceTokenToIntercom: Observable<Data>
  public var authorizeForRemoteNotifications: Observable<Void>
  public var getNotificationAuthorizationStatus: Observable<Void>
}

private func authStatusType(for status: UNAuthorizationStatus) -> NotificationAuthorizationStatus {
  switch status {
  case .authorized: return .authorized
  case .ephemeral: return .authorized
  case .denied: return .denied
  case .notDetermined: return .notDetermined
  case .provisional:
    if #available(iOS 12, *) {
      return .provisional
    } else {
      return .notDetermined
    }
  }
}

