// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSAPI
@testable import ZSLib

class ProductSaveViewModelTests: TestCase {
  private let vm: ProductSaveViewModelType = ProductSaveViewModel()
  private var didSave = TestScheduler(initialClock: 0).createObserver((Product, ShopChange).self)

  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.didSave.subscribe(didSave)
  }

  func testSuccessfulSave() {
    withEnvironment(
      apiService: MockService(),
      apiUploadService: MockUploadService()) {
        let shop = Shop.Templates.fromPersistentStore
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test_image", ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        let picture = EditPicture(url: url)
        picture.startProcess(shopId: shop.id)
        let stock = EditStock(type: .supl, amount: 10, needsUpdate: true)

        let editProduct = EditProduct(
          id: "42",
          name: "Dead Beef",
          description: "dead beef dead beef",
          priceInfo: PriceInfo(amount: 999, currency: "EUR"),
          pictures: [picture, picture],
          stock: stock
        )

        self.vm.inputs.configureWith(shop: shop, saveType: .add(editProduct))

        let visual = Visual(
          width: 600,
          height: 400,
          color: nil,
          kind: "photo",
          url: URL(string: "https://api.supl.test/final_media_url")!
        )

        let product = Product(
          id: "42",
          name: "Dead Beef",
          priceInfo: PriceInfo(amount: 999, currency: "EUR"),
          description: "dead beef dead beef",
          stock: Stock(type: .supl),
          visuals: [visual, visual]
        )

        XCTAssertEqual(didSave.events.first!.value.element!.0, product)
    }
  }

  func testFailFromImageUpload() {
    let err = NSError(domain: "", code: 42, userInfo: nil) as Error
    withEnvironment(
      apiService: MockService(),
      apiUploadService: MockUploadService(uploadError: err)) {

        let shop = Shop.Templates.fromPersistentStore
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test_image", ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        let picture = EditPicture(url: url)
        picture.startProcess(shopId: shop.id)

        let editProduct = EditProduct(
          name: "Dead Beef",
          description: "dead beef dead beef",
          priceInfo: nil,
          pictures: [picture, picture, picture, picture]
        )

        self.vm.inputs.configureWith(shop: shop, saveType: .add(editProduct))
        XCTAssertEqual(didSave.events.map { $0.value.error != nil }.count, 1)
    }
  }

  func testFailFromConfUpdate() {
    let err = NSError(domain: "", code: 42, userInfo: nil) as Error
    withEnvironment(
      apiService: MockService(updateShopError: err),
      apiUploadService: MockUploadService()) {

        let shop = Shop.Templates.fromPersistentStore
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "test_image", ofType: "jpg")!
        let url = URL(fileURLWithPath: path)
        let picture = EditPicture(url: url)
        picture.startProcess(shopId: shop.id)

        let editProduct = EditProduct(
          name: "Dead Beef",
          description: "dead beef dead beef",
          priceInfo: nil,
          pictures: [picture, picture, picture, picture]
        )

        self.vm.inputs.configureWith(shop: shop, saveType: .add(editProduct))
        XCTAssertEqual(didSave.events.map { $0.value.error != nil }.count, 1)
    }
  }
}
