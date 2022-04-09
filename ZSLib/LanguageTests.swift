import XCTest
@testable import ZSLib

final class LanguageTests: XCTestCase {
  func testEquality() {
    XCTAssertEqual(Language.en, Language.en)
    XCTAssertEqual(Language.fr, Language.fr)
    XCTAssertNotEqual(Language.en, Language.fr)
  }
  
  func testInitializer() {
    XCTAssertEqual(Language.en, Language(languageString: "En"))
    XCTAssertEqual(Language.fr, Language(languageString: "Fr"))
    XCTAssertEqual(nil, Language(languageString: "AB"))
  }
  
  func testLanguageFromLanguageStrings() {
    XCTAssertEqual(Language.en, Language(languageStrings: ["AB", "EN", "FR"]))
    XCTAssertEqual(Language.fr, Language(languageStrings: ["AB", "BC", "FR"]))
    XCTAssertEqual(nil, Language(languageStrings: ["AB", "BC", "CD"]))
  }
}
