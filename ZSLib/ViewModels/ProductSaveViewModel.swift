import Foundation
import RxSwift
import RxCocoa
import ZSAPI
import ZSPrelude

public enum ProductSaveType {
  case add(EditProduct)
  case update(EditProduct)
  case delete(EditProduct)
  
  var editProduct: EditProduct {
    switch self {
    case let .add(editProduct):
      return editProduct
    case let .update(editProduct):
      return editProduct
    case let .delete(editProduct):
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

  public func isDelete() -> Bool {
    if case .delete = self { return true }
    return false
  }
}

public protocol ProductSaveViewModelInputs {
  // call to configure
  func configureWith(shop: Shop, saveType: ProductSaveType)
}

public protocol ProductSaveViewModelOutputs {
  // emits when the pictures have been uploaded
  var picturesUpload: Observable<Void> { get }
  
  // emits when the save succeed or failed
  var didSave: Observable<(Product, ShopChange)> { get }
  
  // emits when the progression needs to change
  var setProgression: Observable<Double> { get }

  // emits when the loader should complete
  var shouldCompleteLoader: Observable<Void> { get }
}

public protocol ProductSaveViewModelType {
  var inputs: ProductSaveViewModelInputs { get }
  var outputs: ProductSaveViewModelOutputs { get }
}

public final class ProductSaveViewModel: ProductSaveViewModelType,
  ProductSaveViewModelInputs,
ProductSaveViewModelOutputs {
  
  public enum ViewModelError: Error, LocalizedError {
    case couldNotConvertToProduct
    
    public var errorDescription: String? {
      switch self {
      case .couldNotConvertToProduct: return "couldNotConvertToProduct"
      }
    }
  }
  
  public var inputs: ProductSaveViewModelInputs { return self }
  public var outputs: ProductSaveViewModelOutputs { return self }
  
  public init() {
    let configure = self.configureProperty.unwrap().take(1).share(replay: 1)
    let saveType = configure.map { $0.saveType }
    let editProduct = saveType.map { $0.editProduct }
    let shop = configure.map { $0.shop }

    let shouldCompleteLoader = PublishSubject<Void>()
    let progression = BehaviorRelay<Double>(value: 0)
    
    let pictureProcesses = editProduct
      .map { $0.pictures?.compactMap { $0.process } }
      .unwrap()
    
    let picturesUploadSignal = pictureProcesses.flatMap {
      Observable.zip($0).share(replay: 1)
    }
    
    picturesUpload = picturesUploadSignal.map { _ in () }
    
    let productReady: Observable<Product> = picturesUpload
      .withLatestFrom(Observable.combineLatest(editProduct, shop))
      .flatMap { args in
        updateStockIfNeeded(editProduct: args.0, shopId: args.1.id)
      }
      .withLatestFrom(editProduct)
      .map {
        guard let product = $0.product else { throw ViewModelError.couldNotConvertToProduct }
        return product
      }
      .share(replay: 1)
    
    let shouldAddProduct = Observable.combineLatest(productReady, saveType, shop)
      .filter { $0.1.isAdd() }
      .flatMap { addProduct($0.0, toShop: $0.2) }
      .do(onNext: { _ in progression.accept(1.0) })
      .do(onNext: { _ in shouldCompleteLoader.onNext(()) })
    
    let shouldUpdateProduct = Observable.combineLatest(productReady, saveType, shop)
      .filter { $0.1.isUpdate() }
      .flatMap { updateProduct($0.0, inShop: $0.2) }
      .do(onNext: { _ in progression.accept(1.0) })
      .do(onNext: { _ in shouldCompleteLoader.onNext(()) })

    let shouldDeleteProduct = Observable.combineLatest(productReady, saveType, shop)
      .filter { $0.1.isDelete() }
      .flatMap { deleteProduct($0.0, inShop: $0.2) }
      .do(onNext: { _ in progression.accept(1.0) })
      .do(onNext: { _ in shouldCompleteLoader.onNext(()) })
    
    didSave = Observable.merge(shouldAddProduct, shouldUpdateProduct, shouldDeleteProduct)
    
    setProgression = progression.asObservable()
    self.shouldCompleteLoader = shouldCompleteLoader
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
  public var shouldCompleteLoader: Observable<Void>
}

// MARK: - Utils

private func addProduct(_ product: Product, toShop shop: Shop) -> Observable<(Product, ShopChange)> {
  return shop.addProduct(product)
    .autoRetryOnNetworkError()
    .do(onNext: { _ in
      _ = Product.getFromCacheOrFetchUrl(productId: product.id, shopId: shop.id)
        .subscribe(onNext: {
          UINotificationFeedbackGenerator().notificationOccurred(.success)
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
    .autoRetryOnNetworkError()
    .do(onNext: { _ in
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      AppEnvironment.current.analytics.trackSucceededProductEdition()
      AppEnvironment.current.cache.removeCacheFor(key: ZSCache.zs_product_stocks)
    })
    .do(onError: { error in
      AppEnvironment.current.analytics.trackErroredProductEdition(error: error.localizedDescription)
    })
}

private func deleteProduct(_ product: Product, inShop shop: Shop) -> Observable<(Product, ShopChange)> {
  return shop.deleteProduct(product)
    .autoRetryOnNetworkError()
    .do(onNext: { _ in AppEnvironment.current.analytics.trackSucceededProductDeletion() })
    .do(onError: { error in
      AppEnvironment.current.analytics.trackErroredProductDeletion(error: error.localizedDescription)
    })
}

private func updateStockIfNeeded(editProduct: EditProduct, shopId: String) -> Observable<Void> {
  guard
    let stock = editProduct.stock,
    let amount = stock.amount,
    stock.needsUpdate == true else {
      return Observable.just(())
  }
  
  return AppEnvironment.current.apiService
    .updateStock(
      productId: editProduct.id,
      shopId: shopId,
      amount: amount
    )
    .autoRetryOnNetworkError()
}
