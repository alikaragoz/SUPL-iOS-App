// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSLib
@testable import ZSAPI

class FilePickerViewModelTests: TestCase {
  private let vm: FilePickerViewModelType = FilePickerViewModel()
  private var shouldShowDocumentPicker = TestScheduler(initialClock: 0).createObserver(Void.self)
  private var shouldShowImagePicker = TestScheduler(initialClock: 0).createObserver(Void.self)
  private var shouldShowPickerSource = TestScheduler(initialClock: 0).createObserver(Void.self)
  private var didPickMedias = TestScheduler(initialClock: 0).createObserver([Media].self)

  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.shouldShowDocumentPicker.subscribe(shouldShowDocumentPicker)
    _ = self.vm.outputs.shouldShowImagePicker.subscribe(shouldShowImagePicker)
    _ = self.vm.outputs.shouldShowPickerSource.subscribe(shouldShowPickerSource)
    _ = self.vm.outputs.didPickMedias.subscribe(didPickMedias)
  }

  func testShouldShowPickerSource() {
    self.vm.inputs.addFilesButtonPressed()
    XCTAssertEqual(shouldShowPickerSource.events.count, 1)
  }

  func testShouldShowDocumentPicker() {
    self.vm.inputs.documentPickerButtonPressed()
    XCTAssertEqual(shouldShowDocumentPicker.events.count, 1)
  }

  func testShouldShowImagePicker() {
    self.vm.inputs.imagePickerButtonPressed()
    XCTAssertEqual(shouldShowImagePicker.events.count, 1)
  }

  func testDidPickFiles() {
    let bundle = Bundle(for: type(of: self))
    let path = bundle.path(forResource: "test_image", ofType: "jpg")!
    let url = URL(fileURLWithPath: path)
    let media = Media(url: url, type: .jpg)
    let medias = [media, media]
    self.vm.inputs.mediasPicked(medias: medias)
    XCTAssertEqual(didPickMedias.events.first!.value.element!.count, 2)
  }
}
