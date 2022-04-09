// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSAPI
@testable import ZSLib

class ProductCreationViewModelTests: TestCase {
  private let vm: ProductCreationCoordinatorViewModelType = ProductCreationCoordinatorViewModel()
  private var shouldShowNameStep =
    TestScheduler(initialClock: 0).createObserver(CreatorProduct.self)
  private var shouldNavigateToStep =
    TestScheduler(initialClock: 0).createObserver(ProductCreationNextStep.self)

  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.shouldShowNameStep.subscribe(shouldShowNameStep)
    _ = self.vm.outputs.shouldNavigateToStep.subscribe(shouldNavigateToStep)
  }

  func testShouldShowName() {
    let shop = Shop.Templates.fromPersistentStore
    self.vm.inputs.configureWith(shop: shop)
    self.vm.inputs.didStart()
    XCTAssertEqual(shouldShowNameStep.events, [Recorded.next(0, CreatorProduct())])
  }

  func testLoggedInFlow() {
    let shop = Shop.Templates.fromPersistentStore
    let bundle = Bundle(for: type(of: self))
    let path = bundle.path(forResource: "test_image", ofType: "jpg")!
    let url = URL(fileURLWithPath: path)
    let media = Media(url: url, type: .jpg)
    let medias = [media, media]
    let picture = EditPicture(url: url)
    picture.startProcess(shopId: shop.id)
    let priceInfo = PriceInfo(amount: 100, currency: "EUR")

    let editProduct = EditProduct(
      id: "1",
      name: "Hello",
      priceInfo: priceInfo,
      pictures: [picture, picture]
    )

    let product = editProduct.product!

    AppEnvironment.pushEnvironment()
    AppEnvironment.login(Session(id: "deadbeef", user: "beafdead"))
    self.vm.inputs.configureWith(shop: shop)
    self.vm.inputs.didStart()
    self.vm.inputs.didSubmitWith(step: .name("Hello"))
    self.vm.inputs.didSubmitWith(step: .price(priceInfo))
    self.vm.inputs.didSubmitWith(step: .picture(medias))
    self.vm.inputs.didSubmitWith(step: .review(editProduct))
    self.vm.inputs.didSubmitWith(step: .save(product, .add(0)))
    self.vm.inputs.didSubmitWith(step: .share(product))

    XCTAssertEqual(shouldNavigateToStep.events.description, [
      Recorded.next(0, ProductCreationNextStep.price(nil)),
      Recorded.next(0, ProductCreationNextStep.picture),
      Recorded.next(0, ProductCreationNextStep.review(editProduct, shop)),
      Recorded.next(0, ProductCreationNextStep.save(editProduct, shop)),
      Recorded.next(0, ProductCreationNextStep.share(product)),
      Recorded.next(0, ProductCreationNextStep.end(.add(0)))
      ].description
    )
    AppEnvironment.popEnvironment()
  }

  func testLoggedOutFlow() {
    let shop = Shop.Templates.fromPersistentStore
    let bundle = Bundle(for: type(of: self))
    let path = bundle.path(forResource: "test_image", ofType: "jpg")!
    let url = URL(fileURLWithPath: path)
    let media = Media(url: url, type: .jpg)
    let medias = [media, media]
    let picture = EditPicture(url: url)
    picture.startProcess(shopId: shop.id)
    let priceInfo = PriceInfo(amount: 100, currency: "EUR")

    let editProduct = EditProduct(
      id: "1",
      name: "Hello",
      priceInfo: priceInfo,
      pictures: [picture, picture]
    )

    let product = editProduct.product!

    self.vm.inputs.configureWith(shop: shop)
    self.vm.inputs.didStart()
    self.vm.inputs.didSubmitWith(step: .name("Hello"))
    self.vm.inputs.didSubmitWith(step: .price(priceInfo))
    self.vm.inputs.didSubmitWith(step: .picture(medias))
    self.vm.inputs.didSubmitWith(step: .review(editProduct))
    self.vm.inputs.didSubmitWith(step: .paypal)
    self.vm.inputs.didSubmitWith(step: .save(product, .add(0)))
    self.vm.inputs.didSubmitWith(step: .share(product))

    XCTAssertEqual(shouldNavigateToStep.events.description, [
      Recorded.next(0, ProductCreationNextStep.price(nil)),
      Recorded.next(0, ProductCreationNextStep.picture),
      Recorded.next(0, ProductCreationNextStep.review(editProduct, shop)),
      Recorded.next(0, ProductCreationNextStep.paypal(shop)),
      Recorded.next(0, ProductCreationNextStep.save(editProduct, shop)),
      Recorded.next(0, ProductCreationNextStep.share(product)),
      Recorded.next(0, ProductCreationNextStep.end(.add(0)))
      ].description
    )
  }
}
