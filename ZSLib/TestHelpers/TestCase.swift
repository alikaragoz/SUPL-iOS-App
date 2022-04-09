// swiftlint:disable force_unwrapping weak_delegate
import AVFoundation
import RxSwift
import RxCocoa
import XCTest
@testable import ZSAPI
@testable import ZSLib
@testable import ZSPrelude

internal class TestCase: XCTestCase {
  internal static let interval = DispatchTimeInterval.milliseconds(1)

  internal let apiService = MockService()
  internal let apiUploadService = MockUploadService()
  internal let cache = ZSCache()
  internal let device = MockDevice()
  internal let facebookAppDelegate = MockFacebookAppDelegate()
  internal let mainBundle = MockBundle()
  internal let trackingClient = MockTrackingClient()
  internal let userDefaults = MockKeyValueStore()
  internal let backgroundScheduler = MainScheduler.instance
  internal let mainScheduler = MainScheduler.instance
  internal let uuid = MockUUID()

  override func setUp() {
    super.setUp()
    UIViewController.doBadSwizzleStuff()

    AppEnvironment.pushEnvironment(
      analytics: Analytics(clients: [trackingClient]),
      apiService: apiService,
      apiUploadService: apiUploadService,
      backgroundScheduler: backgroundScheduler,
      cache: cache,
      countryCode: "US",
      device: device,
      facebookAppDelegate: facebookAppDelegate,
      language: .en,
      locale: .init(identifier: "en_US"),
      mainBundle: mainBundle,
      userDefaults: userDefaults,
      uuid: uuid
    )
  }

  override func tearDown() {
    super.tearDown()
    AppEnvironment.popEnvironment()
  }
}
