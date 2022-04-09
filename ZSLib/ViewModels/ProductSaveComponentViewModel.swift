import Foundation
import RxSwift
import RxCocoa
import ZSAPI
import ZSPrelude

public enum ProductSaveType {
  case add(EditProduct)
  case update(EditProduct)

  var editProduct: EditProduct {
    switch self {
    case let .add(editProduct):
      return editProduct
    case let .update(editProduct):
      return editProduct
    }
  }

  public func isAdd() -> Bool {
    if case .add = self { return true }
    return false
  }

  public func isUpdate() -> Bool {
    if case .update = self { return true }
    return false
  }
}

public protocol ProductSaveComponentViewModelInputs {
  // call to configure
  func configureWith(shop: Shop, saveType: ProductSaveType)
}

public protocol ProductSaveComponentViewModelOutputs {
  // emits when the pictures have been uploaded
  var picturesUpload: Observable<Void> { get }

  // emits when the save succeed or failed
  var didSave: Observable<(Product, ShopChange)> { get }

  // emits when the progression needs to change
  var setProgression: Observable<Double> { get }
}

public protocol ProductSaveComponentViewModelType {
  var inputs: ProductSaveComponentViewModelInputs { get }
  var outputs: ProductSaveComponentViewModelOutputs { get }
}

public final class ProductSaveComponentViewModel: ProductSaveComponentViewModelType,
  ProductSaveComponentViewModelInputs,
ProductSaveComponentViewModelOutputs {

  public enum ViewModelError: Error, LocalizedError {
    case couldNotConvertToProduct

    public var errorDescription: String? {
      switch self {
      case .couldNotConvertToProduct: return "couldNotConvertToProduct"
      }
    }
  }

  public var inputs: ProductSaveComponentViewModelInputs { return self }
  public var outputs: ProductSaveComponentViewModelOutputs { return self }

  public init() {

    let configure = self.configureProperty.unwrap().take(1).share(replay: 1)
    let saveType = configure.map { $0.saveType }
    let editProduct = saveType.map { $0.editProduct }
    let shop = configure.map { $0.shop }

    let progression = BehaviorRelay<Double>(value: 0)

    let pictureProcesses = editProduct
      .map { $0.pictures?.compactMap { $0.process } }
      .unwrap()

    let picturesUploadSignal = pictureProcesses.flatMap {
      Observable.merge($0)
        .toArray()
        .share(replay: 1)
    }

    picturesUpload = picturesUploadSignal.map { _ in () }

    let productReady: Observable<Product> = picturesUpload
      .withLatestFrom(editProduct)
      .map {
        guard let product = $0.product else { throw ViewModelError.couldNotConvertToProduct }
        return product
    }

    let shouldAddProduct = productReady.withLatestFrom(
      Observable.combineLatest(productReady, saveType, shop)
      )
      .filter { $0.1.isAdd() }
      .flatMap { addProduct($0.0, toShop: $0.2) }
      .do(onNext: { _ in progression.accept(1.0) })
      .share(replay: 1)

    let shouldUpdateProduct = productReady.withLatestFrom(
      Observable.combineLatest(productReady, saveType, shop)
      )
      .filter { $0.1.isUpdate() }
      .flatMap { updateProduct($0.0, inShop: $0.2) }
      .do(onNext: { _ in progression.accept(1.0) })
      .share(replay: 1)

    didSave = Observable.merge(shouldAddProduct, shouldUpdateProduct)

    setProgression = progression.asObservable()
  }

  // MARK: - Inputs
  private typealias ConfigureParams = (shop: Shop, saveType: ProductSaveType)
  private let configureProperty = BehaviorRelay<ConfigureParams?>(value: nil)
  public func configureWith(shop: Shop, saveType: ProductSaveType) {
    self.configureProperty.accept((shop: shop, saveType: saveType))
  }

  // MARK: - Outputs
  public var picturesUpload: Observable<Void>
  public var didSave: Observable<(Product, ShopChange)>
  public var setProgression: Observable<Double>
}

// MARK: - Utils

private func addProduct(_ product: Product, toShop shop: Shop) -> Observable<(Product, ShopChange)> {
  return shop.addProduct(product)
    .do(onNext: { _ in
      _ = product
        .getFromCacheOrFetchUrl(withShopId: shop.id)
        .subscribe(onNext: {
          AppEnvironment.current.analytics.trackSucceededProductCreation(productUrlString: $0.absoluteString)
        }, onError: { _ in
          AppEnvironment.current.analytics.trackSucceededProductCreation(productUrlString: "")
        })
    })
    .do(onError: { error in
      AppEnvironment.current.analytics.trackErroredProductCreation(error: error.localizedDescription)
    })
}

private func updateProduct(_ product: Product, inShop shop: Shop) -> Observable<(Product, ShopChange)> {
  return shop.updateProduct(product)
    .do(onNext: { _ in
      AppEnvironment.current.analytics.trackSucceededProductEdition()
    })
    .do(onError: { error in
      AppEnvironment.current.analytics.trackErroredProductEdition(error: error.localizedDescription)
    })
}
