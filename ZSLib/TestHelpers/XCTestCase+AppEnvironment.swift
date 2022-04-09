import FBSDKCoreKit
import Foundation
import RxSwift
import XCTest
import ZSAPI
import ZSLib

extension XCTestCase {
  
  // Pushes an environment onto the stack, executes a closure, and then pops the environment from the stack.
  func withEnvironment(_ env: Environment, body: () -> Void) {
    AppEnvironment.pushEnvironment(env)
    body()
    AppEnvironment.popEnvironment()
  }
  
  // Pushes an environment onto the stack, executes a closure, and then pops the environment from the stack.
  func withEnvironment(
    analytics: Analytics = AppEnvironment.current.analytics,
    apiService: ServiceType = AppEnvironment.current.apiService,
    apiUploadService: UploadServiceType = AppEnvironment.current.apiUploadService,
    backgroundScheduler: SchedulerType = AppEnvironment.current.backgroundScheduler,
    cache: ZSCache = AppEnvironment.current.cache,
    countryCode: String = AppEnvironment.current.countryCode,
    device: UIDeviceType = AppEnvironment.current.device,
    facebookAppDelegate: FacebookAppDelegateProtocol = AppEnvironment.current.facebookAppDelegate,
    language: Language = AppEnvironment.current.language,
    locale: Locale = AppEnvironment.current.locale,
    mainBundle: NSBundleType = AppEnvironment.current.mainBundle,
    mainScheduler: SchedulerType = AppEnvironment.current.mainScheduler,
    userDefaults: KeyValueStoreType = AppEnvironment.current.userDefaults,
    body: () -> Void) {
    
    withEnvironment(
      Environment(
        analytics: analytics,
        apiService: apiService,
        apiUploadService: apiUploadService,
        backgroundScheduler: backgroundScheduler,
        cache: cache,
        countryCode: countryCode,
        device: device,
        facebookAppDelegate: facebookAppDelegate,
        language: language,
        locale: locale,
        mainBundle: mainBundle,
        mainScheduler: mainScheduler,
        userDefaults: userDefaults
      ),
      body: body
    )
  }
}
