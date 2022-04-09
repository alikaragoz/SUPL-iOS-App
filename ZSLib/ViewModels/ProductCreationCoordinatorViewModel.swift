import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public enum ProductCreationStep: Equatable {
  case name(String)
  case price(PriceInfo)
  case picture([Media])
  case review(EditProduct)
  case paypal
  case save(Product, ShopChange)
  case share(Product)
}

public enum ProductCreationNextStep: Equatable {
  case price(PriceInfo?)
  case picture
  case review(EditProduct, Shop)
  case paypal(Shop)
  case save(EditProduct, Shop)
  case share(Product)
  case end(ShopChange)
}

public protocol ProductCreationCoordinatorViewModelInputs {
  // call to configure
  func configureWith(shop: Shop)

  // call when the coordinator did start
  func didStart()

  // call when the receiving a back event
  func didGoBack()

  // call when submitting with a step
  func didSubmitWith(step: ProductCreationStep)

  // call when dimissing
  func didDismiss(_ completion: ((Bool) -> Void)?)
}

public protocol ProductCreationCoordinatorViewModelOutputs {
  // emits when the coordinator should dismiss
  var shouldDismiss: Observable<(Bool, ((Bool) -> Void)?)> { get }

  // emits when the coordinator should go the the previous step
  var shouldGoBack: Observable<Void> { get }

  // emits when the name view controller should be shown
  var shouldShowNameStep: Observable<CreatorProduct> { get }

  // emits when the coordinator should navigate to the specified step
  var shouldNavigateToStep: Observable<ProductCreationNextStep> { get }
}

public protocol ProductCreationCoordinatorViewModelType {
  var inputs: ProductCreationCoordinatorViewModelInputs { get }
  var outputs: ProductCreationCoordinatorViewModelOutputs { get }
}

public final class ProductCreationCoordinatorViewModel: ProductCreationCoordinatorViewModelType,
  ProductCreationCoordinatorViewModelInputs,
ProductCreationCoordinatorViewModelOutputs {

  public var inputs: ProductCreationCoordinatorViewModelInputs { return self }
  public var outputs: ProductCreationCoordinatorViewModelOutputs { return self }

  public init() {
    let shop = configureWithProp.unwrap()
    let creatorProductProperty = BehaviorRelay<CreatorProduct>(value: CreatorProduct())
    let editProductProperty =
      BehaviorRelay<EditProduct>(value: EditProduct())
    let shopChange = BehaviorRelay<ShopChange>(value: .add(0))

    shouldNavigateToStep = didSubmitWithStep
      .withLatestFrom(Observable.combineLatest(didSubmitWithStep, shop))
      .map { step, shop in
        switch step {
        case let .name(name):
          var cp = creatorProductProperty.value
          cp.name = name.trimmed()
          creatorProductProperty.accept(cp)
          // TODO: Switch to Double
          return .price(cp.priceInfo)

        case let .price(priceInfo):
          var cp = creatorProductProperty.value
          cp.priceInfo = priceInfo
          creatorProductProperty.accept(cp)
          return .picture

        case let .picture(medias):
          var cp = creatorProductProperty.value
          cp.medias = medias
          creatorProductProperty.accept(cp)
          var editProduct = cp.editProduct
          editProduct.id = shop.getNewProductId()
          return .review(editProduct, shop)

        case let .review(ep):
          editProductProperty.accept(ep)
          if AppEnvironment.current.apiService.session == nil {
            return .paypal(shop)
          } else {
            return .save(ep, shop)
          }

        case .paypal:
          return .save(editProductProperty.value, shop)

        case let .save(product, sc):
          shopChange.accept(sc)
          return .share(product)

        case .share:
          return .end(shopChange.value)
        }
    }

    shouldDismiss = didDismissProperty
      .withLatestFrom(Observable.combineLatest(didDismissProperty, creatorProductProperty))
      .map { (callback, creatorProduct) in
        return (creatorProduct == CreatorProduct(), callback)
    }

    shouldGoBack = didGoBackProperty

    shouldShowNameStep = didStartProperty.withLatestFrom(creatorProductProperty)
  }

  // MARK: - Inputs

  private let configureWithProp = BehaviorRelay<Shop?>(value: nil)
  public func configureWith(shop: Shop) {
    self.configureWithProp.accept(shop)
  }

  private let didStartProperty = PublishSubject<Void>()
  public func didStart() {
    self.didStartProperty.onNext(())
  }

  private let didGoBackProperty = PublishSubject<Void>()
  public func didGoBack() {
    self.didGoBackProperty.onNext(())
  }

  private let didSubmitWithStep = PublishSubject<ProductCreationStep>()
  public func didSubmitWith(step: ProductCreationStep) {
    self.didSubmitWithStep.onNext(step)
  }

  private let didDismissProperty = PublishSubject<((Bool) -> Void)?>()
  public func didDismiss(_ completion: ((Bool) -> Void)?) {
    self.didDismissProperty.onNext(completion)
  }

  // MARK: - Outputs

  public var shouldDismiss: Observable<(Bool, ((Bool) -> Void)?)>
  public var shouldGoBack: Observable<Void>
  public var shouldShowNameStep: Observable<CreatorProduct>
  public var shouldNavigateToStep: Observable<ProductCreationNextStep>
}
