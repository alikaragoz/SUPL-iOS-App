import FBSDKCoreKit
import Foundation
import RxSwift
import ZSAPI

public struct AppEnvironment {
  internal static let environmentStorageKey = "co.supl.AppEnvironment.current"

  // a global stack of environments
  private static var stack: [Environment] = [Environment()]

  // the most recent environment on the stack
  public static var current: Environment! {
    return stack.last
  }

  // invoke when a session has been acquired
  public static func login(_ session: SessionType) {
    replaceCurrentEnvironment(
      apiService: current.apiService.login(session)
    )
  }

  // invoke when you want to end the user's session
  public static func logout() {
    replaceCurrentEnvironment(
      apiService: AppEnvironment.current.apiService.logout(),
      cache: type(of: AppEnvironment.current.cache).init()
    )
  }

  // push a new environment onto the stack
  public static func pushEnvironment(_ env: Environment) {
    saveEnvironment(environment: env, userDefaults: env.userDefaults)
    stack.append(env)
  }

  // pop an environment off the stack
  @discardableResult
  public static func popEnvironment() -> Environment? {
    let last = stack.popLast()
    let next = current ?? Environment()
    saveEnvironment(environment: next, userDefaults: next.userDefaults)
    return last
  }

  // replace the current environment with a new environment
  public static func replaceCurrentEnvironment(_ env: Environment) {
    pushEnvironment(env)
    stack.remove(at: stack.count - 2)
  }

  public static func updateServerConfig(_ config: ServerConfigType) {
    let service = Service(serverConfig: config)
    replaceCurrentEnvironment(
      apiService: service
    )
  }

  // pushes a new environment onto the stack that changes only a subset of the current global dependencies
  public static func pushEnvironment(
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
    uuid: UUIDProviderType = AppEnvironment.current.uuid) {

    pushEnvironment(
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
        userDefaults: userDefaults,
        uuid: uuid
      )
    )
  }

  // replaces the current environment with an environment that changes only a subset of current
  // global dependencies
  public static func replaceCurrentEnvironment(
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
    uuid: UUIDProviderType = AppEnvironment.current.uuid) {

    replaceCurrentEnvironment(
      Environment(
        analytics: analytics,
        apiService: apiService,
        apiUploadService: apiUploadService,
        backgroundScheduler: backgroundScheduler,
        cache: cache,
        device: device,
        facebookAppDelegate: facebookAppDelegate,
        language: language,
        locale: locale,
        mainBundle: mainBundle,
        mainScheduler: mainScheduler,
        userDefaults: userDefaults,
        uuid: uuid
      )
    )
  }

  // saves some key data for the current environment
  internal static func saveEnvironment(environment env: Environment = AppEnvironment.current,
                                       userDefaults: KeyValueStoreType) {
    var data: [String: Any] = [:]

    data["apiService.session.id"] = env.apiService.session?.id
    data["apiService.session.user"] = env.apiService.session?.user
    data["apiService.serverConfig.apiBaseUrl"] = env.apiService.serverConfig.apiBaseUrl.absoluteString
    data["apiService.serverConfig.providerDomain"] = env.apiService.serverConfig.providerDomain
    data["apiService.serverConfig.environment"] = env.apiService.serverConfig.environment.rawValue
    data["apiService.language"] = env.apiService.language

    userDefaults.set(data, forKey: environmentStorageKey)
  }

  // returns the last saved environment from user defaults
  public static func fromStorage(userDefaults: KeyValueStoreType) -> Environment {

    let data = userDefaults.dictionary(forKey: environmentStorageKey) ?? [:]

    var service = current.apiService

    if let id = data["apiService.session.id"] as? String {
      // if there is a session id stored in the defaults, then we can authenticate our api service
      let user = data["apiService.session.user"] as? String
      service = service.login(Session(id: id, user: user))
    }

    /*
    // try restoring the base urls for the api service
    if let apiBaseUrlString = data["apiService.serverConfig.apiBaseUrl"] as? String,
      let apiBaseUrl = URL(string: apiBaseUrlString) {

      service = Service(
        language: current.language.rawValue,
        serverConfig: ServerConfig(
          apiBaseUrl: apiBaseUrl
        ),
        session: service.session
      )
    }

    // try restoring the environment
    if let environment = data["apiService.serverConfig.environment"] as? String,
      let environmentType = EnvironmentType(rawValue: environment) {
      service = Service(
        language: current.language.rawValue,
        serverConfig: ServerConfig(
          apiBaseUrl: service.serverConfig.apiBaseUrl,
          environment: environmentType
        ),
        session: service.session
      )
    }

    // try restoring the domain provider
    if let providerDomain = data["apiService.serverConfig.providerDomain"] as? String {
      service = Service(
        language: current.language.rawValue,
        serverConfig: ServerConfig(
          apiBaseUrl: service.serverConfig.apiBaseUrl,
          providerDomain: providerDomain,
          environment: service.serverConfig.environment
        ),
        session: service.session
      )
    }
    */

    return Environment(
      apiService: service
    )
  }
}
