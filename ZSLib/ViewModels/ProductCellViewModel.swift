import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductCellViewModelInputs {
  // call to configure with Product
  func configureWith(product: Product)

  // call to inform of the cell size
  func setSize(_ size: CGSize)

  // call to inform of a tap on the edit button
  func productCellDidTapEditButton()

  // call to inform of a tap on the share button
  func productCellDidTapShareButton()

  // call to inform of a tap on the preview button
  func productCellDidTapPreviewButton()
}

public protocol ProductCellViewModelOutputs {
  // emits an URL of the image
  var image: Observable<URL> { get }

  // emits text that should be put into the name label
  var name: Observable<String> { get }

  // emits a formatted price
  var price: Observable<String> { get }

  // emits wether the product is disabled
  var disabled: Observable<Bool> { get }

  // emits the product when the edit button is tapped
  var didTapEditButton: Observable<Product> { get }

  // emits the product when the share button is tapped
  var didTapShareButton: Observable<Product> { get }

  // emits the product when the preview button is tapped
  var didTapPreviewButton: Observable<Product> { get }
}

public protocol ProductCellViewModelType {
  var inputs: ProductCellViewModelInputs { get }
  var outputs: ProductCellViewModelOutputs { get }
}

public class ProductCellViewModel: ProductCellViewModelType,
  ProductCellViewModelInputs,
ProductCellViewModelOutputs {

  public var inputs: ProductCellViewModelInputs { return self }
  public var outputs: ProductCellViewModelOutputs { return self }

  public init() {

    let product = productProperty.unwrap().share(replay: 1)
    let size = self.sizeProperty.filter { $0 != .zero }.unwrap()

    image = product
      .flatMapLatest { product -> Observable<URL?> in
        guard let visual = product.visuals.first else {
          trackRuntimeError("Visual can't be nil here")
          return .just(nil)
        }

        if visual.kind == Visual.Kind.cloudflareVideo.rawValue {
          return .just(visual.thumbnail?.url)
        }
        return .just(visual.url)
      }
      .unwrap()
      .flatMap { url -> Observable<(URL, CGSize)> in
        Observable.combineLatest(Observable.just(url), size)
      }
      .map { args in
        return args.0.optimized(
          width: Int(args.1.width * UIScreen.main.scale),
          height: Int(args.1.height * UIScreen.main.scale)
        )
      }
      .unwrap()
      .share(replay: 1)

    name = product.map { $0.name }
    price = product.map {
      Format.currency(
        Double($0.priceInfo.amount) / 100,
        currencySymbol: Currency.currencySymbolFrom(currencyCode: $0.priceInfo.currency)
      )
    }

    disabled = product.map { $0.disabled ?? false }

    didTapEditButton = productCellDidTapEditProperty
      .withLatestFrom(product)

    didTapShareButton = productCellDidTapShareProperty
      .withLatestFrom(product)

    didTapPreviewButton = productCellDidTapPreviewProperty
      .withLatestFrom(product)
  }

  // MARK: - Inputs

  private let productProperty = BehaviorRelay<Product?>(value: nil)
  public func configureWith(product: Product) {
    self.productProperty.accept(product)
  }

  private let sizeProperty = BehaviorRelay<CGSize?>(value: .zero)
  public func setSize(_ size: CGSize) {
    self.sizeProperty.accept(size)
  }

  private let productCellDidTapEditProperty = PublishSubject<Void>()
  public func productCellDidTapEditButton() {
    self.productCellDidTapEditProperty.onNext(())
  }

  private let productCellDidTapShareProperty = PublishSubject<Void>()
  public func productCellDidTapShareButton() {
    self.productCellDidTapShareProperty.onNext(())
  }

  private let productCellDidTapPreviewProperty = PublishSubject<Void>()
  public func productCellDidTapPreviewButton() {
    self.productCellDidTapPreviewProperty.onNext(())
  }

  // MARK: - Outputs

  public var image: Observable<URL>
  public var name: Observable<String>
  public var price: Observable<String>
  public var disabled: Observable<Bool>
  public var didTapEditButton: Observable<Product>
  public var didTapShareButton: Observable<Product>
  public var didTapPreviewButton: Observable<Product>
}
