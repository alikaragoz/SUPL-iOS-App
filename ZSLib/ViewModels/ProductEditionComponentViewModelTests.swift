// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSAPI
@testable import ZSLib

class ProductEditionComponentViewModelTests: TestCase {
  private let vm: ProductEditionComponentViewModelType = ProductEditionComponentViewModel()

  private var _name = TestScheduler(initialClock: 0).createObserver(String.self)
  private var price = TestScheduler(initialClock: 0).createObserver(String.self)
  private var _description = TestScheduler(initialClock: 0).createObserver(String.self)
  private var initialPictures = TestScheduler(initialClock: 0).createObserver([EditPicture].self)
  private var isValid = TestScheduler(initialClock: 0).createObserver(Bool.self)
  private var newPictures = TestScheduler(initialClock: 0).createObserver([EditPicture].self)
  private var deletedPictures = TestScheduler(initialClock: 0).createObserver([EditPicture].self)
  private var shouldPresentNameEdition = TestScheduler(initialClock: 0).createObserver(EditProduct.self)
  private var shouldPresentPriceEdition = TestScheduler(initialClock: 0).createObserver(EditProduct.self)
  private var shouldPresentDescriptionEdition =
    TestScheduler(initialClock: 0).createObserver(EditProduct.self)
  private var shouldSubmit = TestScheduler(initialClock: 0).createObserver(EditProduct.self)
  private var shouldDismiss = TestScheduler(initialClock: 0).createObserver(Bool.self)

  let shop = Shop.Templates.fromPersistentStore
  let editProduct: EditProduct = {
    let url = URL(string: "https://dead.beaf/image")!
    let editPicture = EditPicture(url: url)
    let editProduct = EditProduct(
      id: "42",
      name: "Dead Beef",
      description: "Foo bar and dead beef are on a boat.",
      priceInfo: PriceInfo(amount: 999, currency: "EUR"),
      pictures: [editPicture]
    )
    return editProduct
  }()

  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.name.subscribe(_name)
    _ = self.vm.outputs.price.subscribe(price)
    _ = self.vm.outputs.description.subscribe(_description)
    _ = self.vm.outputs.initialPictures.subscribe(initialPictures)
    _ = self.vm.outputs.isValid.subscribe(isValid)
    _ = self.vm.outputs.newPictures.subscribe(newPictures)
    _ = self.vm.outputs.deletedPictures.subscribe(deletedPictures)
    _ = self.vm.outputs.shouldPresentNameEdition.subscribe(shouldPresentNameEdition)
    _ = self.vm.outputs.shouldPresentPriceEdition.subscribe(shouldPresentPriceEdition)
    _ = self.vm.outputs.shouldPresentDescriptionEdition.subscribe(shouldPresentDescriptionEdition)
    _ = self.vm.outputs.shouldSubmit.subscribe(shouldSubmit)
    _ = self.vm.outputs.shouldDismiss.subscribe(shouldDismiss)
  }

  func testName() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()

    XCTAssertEqual(_name.events, [Recorded.next(0, editProduct.name!)])

    self.vm.inputs.updateName("Foo Bar")
    self.vm.inputs.submitButtonPressed()

    XCTAssertEqual(_name.events, [Recorded.next(0, editProduct.name!), Recorded.next(0, "Foo Bar")])
  }

  func testPrice() {
    withEnvironment(countryCode: "US", locale: Locale(identifier: "en")) {
      let vm: ProductEditionComponentViewModelType = ProductEditionComponentViewModel()
      let price = TestScheduler(initialClock: 0).createObserver(String.self)
      _ = vm.outputs.price.subscribe(price)
      vm.inputs.configureWith(shop: shop, editProduct: editProduct)
      vm.inputs.viewDidLoad()

      XCTAssertEqual(price.events, [Recorded.next(0, "€9.99")])

      vm.inputs.updatePrice(PriceInfo(amount: 222, currency: "EUR"))

      XCTAssertEqual(price.events, [
        Recorded.next(0, "€9.99"),
        Recorded.next(0, "€2.22")
        ]
      )
    }
  }

  func testDescription() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()

    XCTAssertEqual(_description.events, [Recorded.next(0, editProduct.description!)])

    self.vm.inputs.updateDescription("Foo bar and dead beef are not on a boat.")

    XCTAssertEqual(_description.events, [
      Recorded.next(0, editProduct.description!),
      Recorded.next(0, "Foo bar and dead beef are not on a boat.")
      ]
    )
  }

  func testInitialPictures() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()
    XCTAssertEqual(initialPictures.events, [Recorded.next(0, editProduct.pictures!)])
  }

  func testIsValid() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()

    XCTAssertEqual(isValid.events, [Recorded.next(0, true)])

    let url = URL(string: "https://dead.beaf/image")!
    let editPicture = EditPicture(url: url)
    self.vm.inputs.didDeleteFiles([editPicture])

    XCTAssertEqual(isValid.events, [
      Recorded.next(0, true),
      Recorded.next(0, false)
      ]
    )
  }

  func testNewImages() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()

    let url = URL(string: "https://dead.beaf/image/1")!
    let media = Media(url: url, type: .jpg)
    self.vm.inputs.didAddMedias([media])

    let editPicture = EditPicture(url: url)

    XCTAssertEqual(newPictures.events, [Recorded.next(0, [editPicture])])
  }

  func testDeletePictures() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()

    let url = URL(string: "https://dead.beaf/image")!
    let editPicture = EditPicture(url: url)
    self.vm.inputs.didDeleteFiles([editPicture])

    XCTAssertEqual(deletedPictures.events, [Recorded.next(0, [editPicture])])
  }

  func testShouldPresentName() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.namePressed()
    XCTAssertEqual(shouldPresentNameEdition.events, [Recorded.next(0, editProduct)])
  }

  func testShouldPresentPrice() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.pricePressed()
    XCTAssertEqual(shouldPresentPriceEdition.events, [Recorded.next(0, editProduct)])
  }

  func testShouldPresentDesc() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.descriptionPressed()
    XCTAssertEqual(shouldPresentDescriptionEdition.events, [Recorded.next(0, editProduct)])
  }

  func testShouldSubmit() {
    self.vm.inputs.configureWith(shop: shop, editProduct: self.editProduct)
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.updateName("Foo Bar")
    self.vm.inputs.submitButtonPressed()

    var editProduct = self.editProduct
    editProduct.name = "Foo Bar"
    XCTAssertEqual(shouldSubmit.events, [Recorded.next(0, editProduct)])
  }

  func testShouldDismiss() {
    self.vm.inputs.configureWith(shop: shop, editProduct: editProduct)
    self.vm.inputs.viewDidLoad()
    self.vm.inputs.updateName("Foo Bar")
    self.vm.inputs.didDismiss()
    XCTAssertEqual(shouldDismiss.events, [Recorded.next(0, true)])
  }
}
