// swiftlint:disable weak_delegate
import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductsCarouselViewModelInputs {
  // call when the product cell delegate did tap the share button
  func productCellDidTapShareButton(_ product: Product)
  
  // call when the product cell delegate did tap the link button
  func productCellDidTapPreviewButton(_ product: Product)
  
  // call when a product cell has been tapped
  func productCellDidTapProduct(_ product: Product)
}

public protocol ProductsCarouselViewModelOutputs {
  // emits when the share delegate should be called with the specified url
  var shouldCallDidTapShareDelegate: Observable<URL> { get }
  
  // emits when the preview delegate should be called with the specified url
  var shouldCallDidTapPreviewDelegate: Observable<URL> { get }
  
  // emits when the preview delegate should be called with the specified product
  var shouldCallDidTapProductDelegate: Observable<URL> { get }
}

public protocol ProductsCarouselViewModelType {
  var inputs: ProductsCarouselViewModelInputs { get }
  var outputs: ProductsCarouselViewModelOutputs { get }
}

public class ProductsCarouselViewModel: ProductsCarouselViewModelType,
  ProductsCarouselViewModelInputs,
ProductsCarouselViewModelOutputs {
  
  public var inputs: ProductsCarouselViewModelInputs { return self }
  public var outputs: ProductsCarouselViewModelOutputs { return self }
  
  public init() {
    shouldCallDidTapShareDelegate = productCellDidTapShareButtonProperty.cachedURL()
    shouldCallDidTapPreviewDelegate = productCellDidTapPreviewButtonProperty.cachedURL()
    shouldCallDidTapProductDelegate = productCellDidTapProductProperty.cachedURL()
  }
  
  // MARK: - Inputs
  
  private let productCellDidTapShareButtonProperty = PublishSubject<Product>()
  public func productCellDidTapShareButton(_ product: Product) {
    productCellDidTapShareButtonProperty.onNext(product)
  }
  
  private let productCellDidTapPreviewButtonProperty = PublishSubject<Product>()
  public func productCellDidTapPreviewButton(_ product: Product) {
    productCellDidTapPreviewButtonProperty.onNext(product)
  }
  
  private let productCellDidTapProductProperty = PublishSubject<Product>()
  public func productCellDidTapProduct(_ product: Product) {
    productCellDidTapProductProperty.onNext(product)
  }
  
  // MARK: - Outputs
  
  public var shouldCallDidTapShareDelegate: Observable<URL>
  public var shouldCallDidTapPreviewDelegate: Observable<URL>
  public var shouldCallDidTapProductDelegate: Observable<URL>
}

extension ObservableType where E == Product {
  func cachedURL() -> Observable<URL> {
    return flatMap { product in
      Shop.getOrCreate().flatMap {
        Product.getFromCacheOrFetchUrl(productId: product.id, shopId: $0.id)
      }
    }
  }
}
