// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSLib
@testable import ZSAPI

class EditPriceComponentViewModelTests: TestCase {
  private let vm: EditPriceComponentViewModel = EditPriceComponentViewModel()
  private var formattedPriceText = TestScheduler(initialClock: 0).createObserver(String.self)
  private var priceText = TestScheduler(initialClock: 0).createObserver(String.self)
  private var isValid = TestScheduler(initialClock: 0).createObserver(Bool.self)
  private var shouldSubmit = TestScheduler(initialClock: 0).createObserver(PriceInfo.self)
  private var shouldDismiss = TestScheduler(initialClock: 0).createObserver(Bool.self)
  private var showKeyboard = TestScheduler(initialClock: 0).createObserver(Bool.self)
  
  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.formattedPriceText.subscribe(formattedPriceText)
    _ = self.vm.outputs.priceText.subscribe(priceText)
    _ = self.vm.outputs.isValid.subscribe(isValid)
    _ = self.vm.outputs.shouldSubmit.subscribe(shouldSubmit)
    _ = self.vm.outputs.shouldDismiss.subscribe(shouldDismiss)
    _ = self.vm.outputs.showKeyboard.subscribe(showKeyboard)
  }
  
  func testNextButtonState() {
    XCTAssertEqual(isValid.events, [Recorded.next(0, false)])
    
    self.vm.inputs.priceChanged("")
    self.vm.inputs.priceChanged("999")
    self.vm.inputs.priceChanged("")
    
    XCTAssertEqual(isValid.events, [
      Recorded.next(0, false),
      Recorded.next(0, false),
      Recorded.next(0, true),
      Recorded.next(0, false)
      ]
    )
  }
  
  func testShouldGoToNext() {
    withEnvironment(locale: Locale(identifier: "en")) {
      withEnvironment(countryCode: "USD") {
        self.vm.inputs.configureWith(priceInfo: nil)
        self.vm.inputs.viewWillAppear()
        self.vm.inputs.priceChanged("1234")
        self.vm.inputs.submitButtonPressed()

        let correctValues = [
          Recorded.next(0, PriceInfo(amount: 123400, currency: "USD"))
        ]

        XCTAssertEqual(shouldSubmit.events, correctValues)
      }
    }
  }
  
  func testShouldGoToNextWithKeyboardKey() {
    withEnvironment(locale: Locale(identifier: "en")) {
      withEnvironment(countryCode: "USD") {
        self.vm.inputs.configureWith(priceInfo: nil)
        self.vm.inputs.viewWillAppear()
        self.vm.inputs.priceChanged("999")
        self.vm.inputs.priceTextFieldDoneEditing()

        let correctValues = [
          Recorded.next(0, PriceInfo(amount: 99900, currency: "USD"))
        ]

        XCTAssertEqual(shouldSubmit.events, correctValues)
      }
    }
  }
  
  func testPriceValue() {
    withEnvironment(locale: Locale(identifier: "en")) {
      withEnvironment(countryCode: "USD") {
        vm.inputs.priceChanged("0")
        vm.inputs.priceChanged("1234")

        XCTAssertEqual(formattedPriceText.events, [
          Recorded.next(0, ""),
          Recorded.next(0, "0."),
          Recorded.next(0, "1234")
          ]
        )
      }
    }
  }
  
  func testSubmitThenBackThenNextButtonState() {
    withEnvironment(locale: Locale(identifier: "en")) {
      withEnvironment(countryCode: "USD") {
        self.vm.inputs.configureWith(priceInfo: nil)
        self.vm.inputs.viewWillAppear()
        self.vm.inputs.priceChanged("1234")
        self.vm.inputs.submitButtonPressed()
        self.vm.inputs.viewWillAppear()
        self.vm.inputs.submitButtonPressed()
        XCTAssertEqual(shouldSubmit.events.last?.value.element!, PriceInfo(amount: 123400, currency: "USD"))
      }
    }
  }

  func testShouldDismiss() {
    withEnvironment(locale: Locale(identifier: "en")) {
      withEnvironment(countryCode: "USD") {
        self.vm.inputs.configureWith(priceInfo: PriceInfo(amount: 999, currency: "USD"))
        self.vm.inputs.viewWillAppear()
        self.vm.inputs.priceChanged("1234")
        self.vm.inputs.didPressDismiss()

        XCTAssertEqual(shouldDismiss.events, [
          Recorded.next(0, true)
          ]
        )
      }
    }
  }

  func testCompleteFlow() {
    withEnvironment(locale: Locale(identifier: "en")) {
      withEnvironment(countryCode: "USD") {
        self.vm.inputs.configureWith(priceInfo: nil)
        self.vm.inputs.viewWillAppear()
        XCTAssertEqual(showKeyboard.events.last?.value.element!, true)
        XCTAssertEqual(isValid.events.last?.value.element!, false)

        self.vm.inputs.priceChanged("1234")
        XCTAssertEqual(isValid.events.last?.value.element!, true)

        self.vm.inputs.submitButtonPressed()
        XCTAssertEqual(shouldSubmit.events.last?.value.element!, PriceInfo(amount: 123400, currency: "USD"))
      }
    }
  }
}
