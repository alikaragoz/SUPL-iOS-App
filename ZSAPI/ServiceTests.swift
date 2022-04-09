import XCTest
@testable import ZSAPI

final class ServiceTests: XCTestCase {

  func testDefaults() {
    XCTAssertTrue(Service().serverConfig == ServerConfig.production)
    XCTAssertEqual(Service().language, "en")
  }

  func testEquals() {
    let s1 = Service()
    let s2 = Service(serverConfig: ServerConfig.local)
    let s4 = Service(language: "es")

    XCTAssertTrue(s1 == s1)
    XCTAssertTrue(s2 == s2)
    XCTAssertTrue(s4 == s4)

    XCTAssertFalse(s1 == s2)
    XCTAssertFalse(s1 == s4)

    XCTAssertFalse(s2 == s4)
  }
}
