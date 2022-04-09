// swiftlint:disable line_length
import XCTest
import RxSwift
@testable import ZSAPI
import ZSPrelude

final class URLOptimizeTests: XCTestCase {

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  func testOptimizedUrl() {
    let url = URL(string: "https://dead.beaf/image.jpg")!
    let width = 400
    let height = 200
    let optimizedUrl = url.optimized(width: width, height: height)
    XCTAssertEqual(optimizedUrl, URL(string: "https://fast.supl.co/v1/thumb?url=https://dead.beaf/image.jpg&width=400&height=200")!)
  }

  func testOptimizedUrlWithoutHeight() {
    let url = URL(string: "https://dead.beaf/image.jpg")!
    let width = 400
    let optimizedUrl = url.optimized(width: width)
    XCTAssertEqual(optimizedUrl, URL(string: "https://fast.supl.co/v1/thumb?url=https://dead.beaf/image.jpg&width=400&height=400")!)
  }
}
