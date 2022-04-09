import XCTest
@testable import ZSLib

final class StringWhitespaceTests: XCTestCase {
  func testTrimmed() {
    XCTAssertEqual("", " ".trimmed())
    XCTAssertEqual("", "\n".trimmed())
    XCTAssertEqual("", " \n ".trimmed())
    XCTAssertEqual("foo", " foo ".trimmed())
  }
}
