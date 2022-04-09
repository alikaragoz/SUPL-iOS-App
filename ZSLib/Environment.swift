// swiftlint:disable weak_delegate
import FBSDKCoreKit
import Foundation
import RxSwift
import ZSAPI

/// a collection of **all** global variables and singletons that the app wants access to
public struct Environment {
  // a type that exposes endpoints for tracking various Kickstarter events
  public let analytics: Analytics

  // a type that exposes endpoints for fetching SUPL data
  public let apiService: ServiceType

  // a type that exposes endpoints for interacting with the upload service
  public let apiUploadService: UploadServiceType

  // the scheduler to user for background operations
  public let backgroundScheduler: SchedulerType

  // a type that stores a cached dictionary
  public let cache: ZSCache
  
  // the user’s current country
  public let countryCode: String
  
  // the current device running the app
  public let device: UIDeviceType

  // A delegate to handle Facebook initialization and incoming url requests
  public let facebookAppDelegate: FacebookAppDelegateProtocol
  
  // the user’s current language
  public let language: Language
  
  // the user’s current locale, which determines how numbers are formatted. Default value is
  // `Locale.current`.
  public let locale: Locale
  
  // a type that exposes how to interface with an NSBundle. Default value is `Bundle.main`
  public let mainBundle: NSBundleType

  // the scheduler to user for UI operations
  public let mainScheduler: SchedulerType
  
  // a user defaults key-value store. Default value is `NSUserDefaults.standard`
  public let userDefaults: KeyValueStoreType

  // a type that exposes how to interface with a UUID.
  public let uuid: UUIDProviderType
  
  public init(
    analytics: Analytics = Analytics(clients: [AmplitudeClient(env: .prod), IntercomClient(env: .prod)]),
    apiService: ServiceType = Service(),
    apiUploadService: UploadServiceType = UploadService(),
    backgroundScheduler: SchedulerType = ConcurrentDispatchQueueScheduler(qos: .userInitiated),
    cache: ZSCache = ZSCache(),
    countryCode: String = Locale.current.regionCode ?? "US",
    device: UIDeviceType = UIDevice.current,
    facebookAppDelegate: FacebookAppDelegateProtocol = FBSDKApplicationDelegate.sharedInstance(),
    language: Language = Language(languageStrings: Locale.preferredLanguages) ?? Language.en,
    locale: Locale = .current,
    mainBundle: NSBundleType = Bundle.main,
    mainScheduler: SchedulerType = MainScheduler.instance,
    userDefaults: KeyValueStoreType = UserDefaults.standard,
    uuid: UUIDProviderType = UUIDProvider()) {
    self.analytics = analytics
    self.apiService = apiService
    self.apiUploadService = apiUploadService
    self.backgroundScheduler = backgroundScheduler
    self.cache = cache
    self.countryCode = countryCode
    self.device = device
    self.facebookAppDelegate = facebookAppDelegate
    self.language = language
    self.locale = locale
    self.mainBundle = mainBundle
    self.mainScheduler = mainScheduler
    self.userDefaults = userDefaults
    self.uuid = uuid
  }
}
