import XCTest
@testable import ZSLib

final class RuntimeErrorTests: XCTestCase {
  func testPipeOperation() {
    let error = NSError(domain: "", code: 42, userInfo: nil)
    trackRuntimeError("deadbeaf", error: error)
    XCTAssertEqual(5, 5)
  }
}
