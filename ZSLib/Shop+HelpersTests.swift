import RxSwift
import XCTest
@testable import ZSLib
@testable import ZSAPI

final class ShopHelpersTests: XCTestCase {
  internal var userDefaults: KeyValueStoreType!

  override func setUp() {
    super.setUp()
    self.userDefaults = MockKeyValueStore()
  }

  func testGetOrCreateWithLocalShop() {
    userDefaults.shop = Shop.Templates.fromPersistentStore

    withEnvironment(apiService: MockService(createShopResponse: Shop.Templates.fromApiService),
                    userDefaults: userDefaults) {
      Shop.getOrCreate().subscribe(onNext: {
        XCTAssertEqual($0, Shop.Templates.fromPersistentStore)
      }, onError: { _ in
        XCTFail("Error is not an option here.")
      }).dispose()
    }
  }

  func testGetOrCreateWithoutLocalShop() {
    withEnvironment(apiService: MockService(createShopResponse: Shop.Templates.fromApiService),
                    userDefaults: userDefaults) {
      Shop.getOrCreate().subscribe(onNext: {
        XCTAssertEqual($0, Shop.Templates.fromApiService)
      }, onError: { _ in
        XCTFail("Error is not an option here.")
      }).dispose()
    }
  }

  func testGetOrCreateApiServiceFail() {
    let error = NSError(domain: "", code: 42, userInfo: nil)
    withEnvironment(apiService: MockService(createShopError: error), userDefaults: userDefaults) {
      Shop.getOrCreate().subscribe(onNext: { _ in
        XCTFail("Success is not an option here.")
      }, onError: {
        XCTAssertNotNil($0)
      }).dispose()
    }
  }
}
