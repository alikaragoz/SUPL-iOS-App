// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSAPI
@testable import ZSLib

class ShopSaveViewModelTests: TestCase {
  private let vm: ShopSaveViewModelType = ShopSaveViewModel()
  private var didSave = TestScheduler(initialClock: 0).createObserver(Shop.self)

  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.didSave.subscribe(didSave)
  }

  func testSuccessfulSave() {
    withEnvironment(
      apiService: MockService(),
      apiUploadService: MockUploadService()) {
        let shop = Shop.Templates.fromPersistentStore
        var editShop = shop.editShop
        editShop.domain = "dead-beef.supl.co"
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test_image", ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        let picture = EditPicture(url: url)
        picture.startProcess(shopId: shop.id)
        let editCompanyInfo = EditCompanyInfo(name: "Dead Beef Company", editPicture: picture)
        editShop.conf?.companyInfo = editCompanyInfo
        let newShop = editShop.shop

        self.vm.inputs.configureWith(editShop: editShop)
        XCTAssertEqual(didSave.events.first!.value.element, newShop)
    }
  }

  func testSuccessfulSaveWithoutPictureProcess() {
    withEnvironment(
      apiService: MockService(),
      apiUploadService: MockUploadService()) {
        let shop = Shop.Templates.fromPersistentStore
        var editShop = shop.editShop
        editShop.domain = "dead-beef.supl.co"
        let editCompanyInfo = EditCompanyInfo(name: "Dead Beef Company")
        editShop.conf?.companyInfo = editCompanyInfo
        let newShop = editShop.shop

        self.vm.inputs.configureWith(editShop: editShop)
        XCTAssertEqual(didSave.events.first!.value.element, newShop)
    }
  }

  func testFailFromImageUpload() {
    let err = NSError(domain: "", code: 42, userInfo: nil) as Error
    withEnvironment(
      apiService: MockService(),
      apiUploadService: MockUploadService(uploadError: err)) {
        let shop = Shop.Templates.fromPersistentStore
        var editShop = shop.editShop
        editShop.domain = "dead-beef.supl.co"
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test_image", ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        let picture = EditPicture(url: url)
        picture.startProcess(shopId: shop.id)
        let editCompanyInfo = EditCompanyInfo(name: "Dead Beef Company", editPicture: picture)
        editShop.conf?.companyInfo = editCompanyInfo

        self.vm.inputs.configureWith(editShop: editShop)
        XCTAssertEqual(didSave.events.map { $0.value.error != nil }.count, 2)
    }
  }

  func testFailFromConfUpdate() {
    let err = NSError(domain: "", code: 42, userInfo: nil) as Error
    withEnvironment(
      apiService: MockService(updateShopError: err),
      apiUploadService: MockUploadService()) {
        let shop = Shop.Templates.fromPersistentStore
        var editShop = shop.editShop
        editShop.domain = "dead-beef.supl.co"
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test_image", ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        let picture = EditPicture(url: url)
        picture.startProcess(shopId: shop.id)
        let editCompanyInfo = EditCompanyInfo(name: "Dead Beef Company", editPicture: picture)
        editShop.conf?.companyInfo = editCompanyInfo

        self.vm.inputs.configureWith(editShop: editShop)
        XCTAssertEqual(didSave.events.map { $0.value.error != nil }.count, 1)
    }
  }
}
