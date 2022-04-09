import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol ProductCreationShareViewModelInputs {
  // call to configure with Product
  func configureWith(product: Product)

  // call when the copy link button is pressed
  func copyLinkButtonPressed()

  // call when the skip button is pressed
  func skipButtonPressed()

  // call when the browser has been tapped
  func browserPressed()

  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductCreationShareViewModelOutputs {
  // emits the product url
  var shopDomain: Observable<URL> { get }

  // emits when the safari webview needs to be presented
  var presentSafariWebview: Observable<URL> { get }

  // emits when the vc should submit
  var shouldGoToNext: Observable<Product> { get }
}

public protocol ProductCreationShareViewModelType {
  var inputs: ProductCreationShareViewModelInputs { get }
  var outputs: ProductCreationShareViewModelOutputs { get }
}

public final class ProductCreationShareViewModel: ProductCreationShareViewModelType,
  ProductCreationShareViewModelInputs,
ProductCreationShareViewModelOutputs {

  public var inputs: ProductCreationShareViewModelInputs { return self }
  public var outputs: ProductCreationShareViewModelOutputs { return self }

  private let disposeBag = DisposeBag()

  public init() {

    let shop = viewDidAppearProperty
      .flatMap { Shop.getOrCreate() }
      .share(replay: 1)

    shopDomain = shop.map { URL(string: "https://" + $0.domain) }.unwrap()

    presentSafariWebview = browserPressedProperty.withLatestFrom(shopDomain)

    shouldGoToNext = Observable
      .merge(skipButtonPressedProperty, copyLinkButtonPressedProperty)
      .withLatestFrom(productProperty)
      .unwrap()

    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedCreateProductShare() }
      .disposed(by: disposeBag)

    presentSafariWebview
      .subscribe { _ in AppEnvironment.current.analytics.trackPreviewedProduct(context: .create) }
      .disposed(by: disposeBag)

    copyLinkButtonPressedProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackCopiedLinkDuringCreation() }
      .disposed(by: disposeBag)

    copyLinkButtonPressedProperty
      .withLatestFrom(shopDomain)
      .subscribe(onNext: { UIPasteboard.general.string = $0.absoluteString })
      .disposed(by: disposeBag)

    skipButtonPressedProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackSkippedShareDuringCreation() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let productProperty = BehaviorRelay<Product?>(value: nil)
  public func configureWith(product: Product) {
    self.productProperty.accept(product)
  }

  private let browserPressedProperty = PublishSubject<Void>()
  public func browserPressed() {
    self.browserPressedProperty.onNext(())
  }

  private let copyLinkButtonPressedProperty = PublishSubject<Void>()
  public func copyLinkButtonPressed() {
    self.copyLinkButtonPressedProperty.onNext(())
  }

  private let skipButtonPressedProperty = PublishSubject<Void>()
  public func skipButtonPressed() {
    self.skipButtonPressedProperty.onNext(())
  }

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs

  public var shouldGoToNext: Observable<Product>
  public var presentSafariWebview: Observable<URL>
  public var shopDomain: Observable<URL>
}
