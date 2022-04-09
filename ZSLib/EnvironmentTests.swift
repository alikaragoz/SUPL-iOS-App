import XCTest
@testable import ZSLib

final class EnvironmentTests: XCTestCase {
  
  func testInit() {
    let env = Environment()
    XCTAssertEqual(env.language, Language(languageStrings: Locale.preferredLanguages))
  }
}
