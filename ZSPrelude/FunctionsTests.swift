import XCTest
import ZSPrelude

final class FunctionsTests: XCTestCase {
  func testPipeOperation() {
    func square(_ x: Int) -> Int { return x * x }
    
    XCTAssertEqual(4, 2 |> square)
  }
  
  func testDiamondOperation() {
    let redColorBackground: (UIView) -> UIView = {
      $0.backgroundColor = .red
      return $0
    }
    let roundCorner: (UIView) -> UIView = {
      $0.layer.cornerRadius = 5
      return $0
    }
    
    let button = UIButton() |> redColorBackground <> roundCorner
    
    XCTAssertEqual(.red, button.backgroundColor)
    XCTAssertEqual(5, button.layer.cornerRadius)
  }
}
