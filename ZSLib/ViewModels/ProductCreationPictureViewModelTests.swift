// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSLib
@testable import ZSAPI

class ProductCreationPictureViewModelTests: TestCase {
  private let vm: ProductCreationPictureViewModelType = ProductCreationPictureViewModel()
  private var shouldGoToNext = TestScheduler(initialClock: 0).createObserver([Media].self)

  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.shouldGoToNext.subscribe(shouldGoToNext)
  }

  func testShouldGoToNext() {
    withEnvironment(apiService: MockService(), apiUploadService: MockUploadService()) {

      let bundle = Bundle(for: type(of: self))
      let path = bundle.path(forResource: "test_image", ofType: "jpg")!
      let url = URL(fileURLWithPath: path)
      let media = Media(url: url, type: .jpg)
      let medias = [media, media]

      self.vm.inputs.mediasPicked(medias: medias)

      XCTAssertEqual(shouldGoToNext.events, [
        Recorded.next(0, medias)
        ])
    }
  }
}
