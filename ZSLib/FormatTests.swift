// swiftlint:disable force_unwrapping
import XCTest
@testable import ZSLib

final class FormatTests: XCTestCase {
  
  func testCurrency() {
    withEnvironment(locale: Locale(identifier: "en")) {
      withEnvironment(countryCode: "US") {
        XCTAssertEqual(Format.currency(1_000, currencySymbol: "$"), "$1,000.00")
        XCTAssertEqual(Format.currency(1_000, currencySymbol: "€"), "€1,000.00")
      }
      
      withEnvironment(countryCode: "FR") {
        XCTAssertEqual(Format.currency(1_000, currencySymbol: "$"), "$1,000.00")
        XCTAssertEqual(Format.currency(1_000, currencySymbol: "€"), "€1,000.00")
      }
    }
    
    withEnvironment(locale: Locale(identifier: "fr")) {
      withEnvironment(countryCode: "US") {
        XCTAssertEqual(Format.currency(1_000, currencySymbol: "€"), "1 000,00 €")
      }
      
      withEnvironment(countryCode: "FR") {
        XCTAssertEqual(Format.currency(1_000, currencySymbol: "€"), "1 000,00 €")
      }
    }
  }
}
