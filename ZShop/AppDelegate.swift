import Crashlytics
import Fabric
import FBSDKCoreKit
import Intercom
import RxCocoa
import RxSwift
import UIKit
import UserNotifications
import ZShop_Framework
import ZSLib

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  private let viewModel: AppDelegateViewModelType = AppDelegateViewModel()
  private let disposeBag = DisposeBag()
  var window: UIWindow?

  internal var rootViewController: UINavigationController? {
    return self.window?.rootViewController as? UINavigationController
  }
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    UIViewController.doBadSwizzleStuff()

    AppEnvironment.replaceCurrentEnvironment(
      AppEnvironment.fromStorage(
        userDefaults: UserDefaults.standard
      )
    )

    // NB: We have to push this shared instance directly because somehow we get two different shared
    //     instances if we use the one from `Environment.init`.
    AppEnvironment.replaceCurrentEnvironment(facebookAppDelegate: FBSDKApplicationDelegate.sharedInstance())

    if AppEnvironment.current.mainBundle.isDebug || AppEnvironment.current.mainBundle.isLocal {
      AppEnvironment.replaceCurrentEnvironment(analytics: Analytics(clients: [
        AmplitudeClient(env: .dev),
        IntercomClient(env: .dev)
        ])
      )
    }

    viewModel.outputs.configureFabric
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        guard let `self` = self else { return }

        Fabric.with([Crashlytics.self])

        let crashlytics = Crashlytics.sharedInstance()
        crashlytics.delegate = self

        if let sessionId = AppEnvironment.current.analytics.sessionId() {
          crashlytics.setObjectValue(sessionId, forKey: "Session Id")
        }

        if let deviceId = AppEnvironment.current.analytics.deviceId() {
          crashlytics.setObjectValue(deviceId, forKey: "Device Id")
        }
      })
      .disposed(by: disposeBag)

    viewModel.outputs.configureIntercom
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: {

        if AppEnvironment.current.mainBundle.isRelease {
          Intercom.setApiKey(Secrets.Intercom.Prod.apiKey, forAppId: Secrets.Intercom.Prod.appId)
        } else {
          Intercom.setApiKey(Secrets.Intercom.Dev.apiKey, forAppId: Secrets.Intercom.Dev.appId)
        }

        if let user = AppEnvironment.current.userDefaults.paypalUser {
          Intercom.registerUser(withEmail: user.email)
          let userAttr = ICMUserAttributes()
          userAttr.name = [user.firstName, user.lastName].joined(separator: " ")
          userAttr.email = user.email
          Intercom.updateUser(userAttr)
        } else {
          Intercom.registerUnidentifiedUser()
        }
      })
    .disposed(by: disposeBag)

    viewModel.outputs.configureRxHook
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: {
        Hooks.recordCallStackOnError = true
        Hooks.customCaptureSubscriptionCallstack = { Thread.callStackSymbols }
        Hooks.defaultErrorHandler = { subscriptionCallStack, error in
          let serializedCallStack = subscriptionCallStack.joined(separator: "\n")
          trackRuntimeError(
            "Unhandled error happened, Subscription called from:\n\(serializedCallStack)",
            error: error
          )
        }
      })
      .disposed(by: disposeBag)

    viewModel.outputs.registerForRemoteNotifications
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: {
        UIApplication.shared.registerForRemoteNotifications()
    })
    .disposed(by: disposeBag)

    viewModel.outputs.shouldSendDeviceTokenToIntercom
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: {
        Intercom.setDeviceToken($0)
      })
      .disposed(by: disposeBag)

    self.viewModel.outputs.getNotificationAuthorizationStatus
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          self?.viewModel.inputs.notificationAuthorizationStatusReceived(settings.authorizationStatus)
        }
      })
      .disposed(by: disposeBag)

    viewModel.outputs.authorizeForRemoteNotifications
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        UNUserNotificationCenter
          .current()
          .requestAuthorization(options: [.badge, .sound, .alert]) { (isGranted, _) in
            self?.viewModel.inputs.notificationAuthorizationCompleted(isGranted: isGranted)
        }
      })
      .disposed(by: disposeBag)

    viewModel.inputs.applicationDidFinishLaunching(
      application: application,
      launchOptions: launchOptions
    )

    let homeViewController = HomeViewController.instance()
    rootViewController?.view.backgroundColor = .white
    rootViewController?.setViewControllers([homeViewController], animated: true)

    //swiftlint:disable discarded_notification_center_observer
    NotificationCenter.default.addObserver(
      forName: Notification.Name.zs_showNotificationsDialog,
      object: nil,
      queue: nil) { [weak self] _ in
        self?.viewModel.inputs.requestRegisterForRemoteNotifications()
    }

    return true
  }

  func application(_ app: UIApplication, open url: URL,
                   options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    guard let sourceApplication = options[.sourceApplication] as? String else { return false }

    return self.viewModel.inputs.applicationOpenUrl(application: app,
                                                    url: url,
                                                    sourceApplication: sourceApplication,
                                                    annotation: options[.annotation] as Any)
  }

  func application(_ application: UIApplication,
                   open url: URL,
                   sourceApplication: String?,
                   annotation: Any) -> Bool {

    return self.viewModel.inputs.applicationOpenUrl(application: application,
                                                    url: url,
                                                    sourceApplication: sourceApplication,
                                                    annotation: annotation)
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    self.viewModel.inputs.applicationDidBecomeActive()
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    self.viewModel.inputs.applicationWillEnterForeground()
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    self.viewModel.inputs.applicationDidEnterBackground()
  }

  internal func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    self.viewModel.inputs.didRegisterForRemoteNotifications(withDeviceTokenData: deviceToken)
  }
}

// MARK: - CrashlyticsDelegate

extension AppDelegate: CrashlyticsDelegate {
  public func crashlyticsDidDetectReport(forLastExecution report: CLSReport,
                                         completionHandler: @escaping (Bool) -> Void) {
    self.viewModel.inputs.crashlyticsDidDetectReport()
    completionHandler(true)
  }
}
