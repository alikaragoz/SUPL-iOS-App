// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSLib

class EditNameComponentViewModelTests: TestCase {
  private let vm: EditNameComponentViewModelType = EditNameComponentViewModel()
  private var nameText = TestScheduler(initialClock: 0).createObserver(String.self)
  private var isValid = TestScheduler(initialClock: 0).createObserver(Bool.self)
  private var shouldSubmit = TestScheduler(initialClock: 0).createObserver(String.self)
  private var shouldDismiss = TestScheduler(initialClock: 0).createObserver(Bool.self)
  private var showKeyboard = TestScheduler(initialClock: 0).createObserver(Bool.self)
  
  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.nameText.subscribe(nameText)
    _ = self.vm.outputs.isValid.subscribe(isValid)
    _ = self.vm.outputs.shouldSubmit.subscribe(shouldSubmit)
    _ = self.vm.outputs.shouldDismiss.subscribe(shouldDismiss)
    _ = self.vm.outputs.showKeyboard.subscribe(showKeyboard)
  }
  
  func testNextButtonState() {
    self.vm.inputs.configureWith(name: "")
    self.vm.inputs.viewWillAppear()
    self.vm.inputs.nameChanged("")
    self.vm.inputs.nameChanged("Hello")
    self.vm.inputs.nameChanged("")

    XCTAssertEqual(isValid.events, [
      Recorded.next(0, false),
      Recorded.next(0, false),
      Recorded.next(0, false),
      Recorded.next(0, true),
      Recorded.next(0, false)
      ]
    )
  }
  
  func testShouldGoToNext() {
    self.vm.inputs.configureWith(name: "")
    self.vm.inputs.viewWillAppear()
    self.vm.inputs.nameChanged("Hello")
    self.vm.inputs.submitButtonPressed()

    XCTAssertEqual(shouldSubmit.events, [Recorded.next(0, "Hello")])
  }
  
  func testShouldGoToNextWithKeyboardKey() {
    self.vm.inputs.configureWith(name: "")
    self.vm.inputs.viewWillAppear()
    self.vm.inputs.nameChanged("Hello")
    self.vm.inputs.nameTextFieldDoneEditing()

    XCTAssertEqual(shouldSubmit.events, [Recorded.next(0, "Hello")])
  }

  func testNameValue() {
    self.vm.inputs.configureWith(name: "")
    self.vm.inputs.viewWillAppear()
    self.vm.inputs.nameChanged("Hello")
    self.vm.inputs.nameChanged("Hello You")

    XCTAssertEqual(nameText.events, [
      Recorded.next(0, ""),
      Recorded.next(0, ""),
      Recorded.next(0, "Hello"),
      Recorded.next(0, "Hello You")
      ]
    )
  }

  func testShouldDismiss() {
    self.vm.inputs.configureWith(name: "Hello")
    self.vm.inputs.viewWillAppear()
    self.vm.inputs.nameChanged("Hellos")
    self.vm.inputs.didPressDismiss()
    self.vm.inputs.nameChanged("Hello")
    self.vm.inputs.didPressDismiss()

    XCTAssertEqual(shouldDismiss.events, [
      Recorded.next(0, true),
      Recorded.next(0, false)
      ]
    )
  }
  
  func testCompleteFlow() {
    self.vm.inputs.configureWith(name: "")
    self.vm.inputs.viewWillAppear()
    XCTAssertEqual(showKeyboard.events.last?.value.element!, true)
    XCTAssertEqual(isValid.events.last?.value.element!, false)
    
    self.vm.inputs.nameChanged("     Hello You    ")
    XCTAssertEqual(isValid.events.last?.value.element!, true)

    self.vm.inputs.submitButtonPressed()
    XCTAssertEqual(shouldSubmit.events.last?.value.element!, "Hello You")
  }
}
