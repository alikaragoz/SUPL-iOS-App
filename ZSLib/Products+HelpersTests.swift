import RxSwift
import XCTest
@testable import ZSLib
@testable import ZSAPI

final class ProductHelpersTests: XCTestCase {
  internal var cache: ZSCache!

  override func setUp() {
    super.setUp()
    self.cache = ZSCache()
  }

  func testGetFromCacheOrFetchProductWithLocalUrl() {
    cache[ZSCache.zs_product_urls] = [Product.template.id: URL(string: "https://deadb.beaf/product")!]
    withEnvironment(apiService: MockService(), cache: cache) {
      Product.getFromCacheOrFetchUrl(productId: "deadbeaf", shopId: "deadbeaf")
        .subscribe(onNext: {
          XCTAssertEqual($0, URL(string: "https://deadb.beaf/product")!)
        }, onError: { _ in
          XCTFail("Error is not an option here.")
        }).dispose()
    }
  }

  func testGetFromCacheOrFetchProductWithoutLocalUrl() {
    withEnvironment(apiService: MockService(getProductUrlResponse: .template), cache: cache) {
      Product.getFromCacheOrFetchUrl(productId: "deadbeaf", shopId: "deadbeaf")
        .subscribe(onNext: {
          XCTAssertEqual($0, ProductUrlResponse.template.url)
        }, onError: { _ in
          XCTFail("Error is not an option here.")
        }).dispose()
    }
  }

  func testGetOrCreateApiServiceFail() {
    let error = NSError(domain: "", code: 42, userInfo: nil)
    withEnvironment(apiService: MockService(getProductUrlError: error), cache: cache) {
      Product.getFromCacheOrFetchUrl(productId: "deadbeaf", shopId: "deadbeaf")
        .subscribe(onNext: { _ in
          XCTFail("Success is not an option here.")
        }, onError: {
          XCTAssertNotNil($0)
        }).dispose()
    }
  }
}
