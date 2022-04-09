import XCTest
@testable import ZSPrelude

private struct User {
  var name: String?
  var email: String?
}

extension User: Then {}

class ThenTests: XCTestCase {

  func testThen() {
    let queue = OperationQueue().then {
      $0.name = "deadbeaf"
      $0.maxConcurrentOperationCount = 5
    }
    XCTAssertEqual(queue.name, "deadbeaf")
    XCTAssertEqual(queue.maxConcurrentOperationCount, 5)
  }

  func testWith() {
    let user = User().with {
      $0.name = "deadbeaf"
      $0.email = "deadbeaf@gmail.com"
    }
    XCTAssertEqual(user.name, "deadbeaf")
    XCTAssertEqual(user.email, "deadbeaf@gmail.com")
  }

  func testDo() {
    UserDefaults.standard.do {
      $0.removeObject(forKey: "username")
      $0.set("deadbeaf", forKey: "username")
      $0.synchronize()
    }
    XCTAssertEqual(UserDefaults.standard.string(forKey: "username"), "deadbeaf")
  }

  func testRethrows() {
    XCTAssertThrowsError(
      try NSObject().do { _ in
        throw NSError(domain: "", code: 0)
      }
    )
  }
}
