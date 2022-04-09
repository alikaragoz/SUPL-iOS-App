import Foundation
import RxCocoa
import RxSwift
import ZSAPI
import ZSPrelude

public protocol HomeViewControllerViewModelInputs {
  // call when the add product button is pressed
  func addProductButtonPressed()

  // call when the intercom button is pressed
  func intercomButtonPressed()
  
  // call to notify a product had been added at the index
  func productAddedAt(index: Int)
  
  // call to notify a product had been edited at the index
  func productEditedAt(index: Int)

  // call to notify a product had been deleted at the index
  func productDeletedAt(index: Int)

  // call the notify the shop had beed edited
  func shopEdited(_ shop: Shop)

  // call to pop the shop edition
  func shopEditionPropDidGoBack()

  // call to pop the productedition edition
  func productEditionPropDidGoBack()
  
  // call when the focus is on a product in the carousel
  func focusOnProduct(_ product: Product?)

  // call when the paypal status has beed tapped
  func paypalStatusTapped()
  
  // call when the add button is pressed in the carousel
  func productsCarouselDidTapAdd()
  
  // call when the edit button is pressed in the carousel
  func productsCarouselDidTapEditProduct(_ product: Product)
  
  // call when the preview button is pressed in the carousel
  func productsCarouselDidTapPreviewWithURL(_ url: URL?)
  
  // call when the share button is pressed in the carousel
  func productsCarouselDidTapShareWithURL(_ url: URL?)

  // call when a product is tapped in the carousel
  func productsCarouselDidTapProductWithUrl(_ url: URL?)

  // call when the share did complete
  func shareDidComplete(activityType: UIActivity.ActivityType?,
                        completed: Bool,
                        returnedItems: [Any]?,
                        activityError: Error?)

  // call to update the paypal status
  func updatePaypalStatus()

  // call when the shop header is tapped
  func shopHeaderTapped()

  // call when the settings button of the header is tapped
  func shopHeaderSettingsTapped()
  
  // call when the view did appear
  func viewDidAppear()

  // call when the view will disappear
  func viewWillDisappear()

  // call when the view will appear
  func viewWillAppear()
}

public protocol HomeViewControllerViewModelOutputs {
  // emits a Shop or not
  var shop: Observable<Shop> { get }
  
  // emits when a product has been added
  var productAdded: Observable<([Product], Int)> { get }
  
  // emits when a product has been edited
  var productEdited: Observable<([Product], Int)> { get }

  // emits when a product has been deleted
  var productDeleted: Observable<([Product], Int)> { get }

  // emits when the product creation flow should start
  var shouldStartProductCreation: Observable<Shop> { get }
  
  // emits when the edit product flow should start
  var shouldEditProduct: Observable<(EditProduct, Shop)> { get }
  
  // emits when the share dialog should be shown
  var shouldShowShareDialog: Observable<URL> { get }
  
  // emits when the safari preview should be shown
  var shouldPreviewProduct: Observable<URL> { get }

  // emits whether paypal status should be visible
  var paypalStatusVisible: Observable<Bool> { get }

  // emits when the paypal connect should be shown
  var shouldShowPaypalConnect: Observable<Shop> { get }

  // emits whether the empty state should be shown
  var shouldShowEmptyState: Observable<Bool> { get }

  // emits when the shop preview should be shown
  var shouldPreviewShop: Observable<URL> { get }

  // emits when the shop should be edited
  var shouldEditShop: Observable<EditShop> { get }

  // emits when the should has been edited
  var shopEdited: Observable<Shop> { get }

  // emits when the should has been updated
  var shopUpdated: Observable<Shop> { get }

  // emits when the shop edition needs to be popped
  var shouldPopShopEdition: Observable<Void> { get }

  // emits when the product edition needs to be popped
  var shouldPopProductEdition: Observable<Void> { get }

  // emits whether the Intercom bubble should be shown
  var shouldShowIntercomButton: Observable<Bool> { get }

  // emits when the Intercom window should be shown
  var shouldShowIntercomWindow: Observable<Void> { get }
}

public protocol HomeViewControllerViewModelType {
  var inputs: HomeViewControllerViewModelInputs { get }
  var outputs: HomeViewControllerViewModelOutputs { get }
}

public enum HomeViewControllerViewModelError: Error, LocalizedError {
  case couldNotGetProducts

  public var errorDescription: String? {
    switch self {
    case .couldNotGetProducts: return "couldNotGetProducts"
    }
  }
}

public class HomeViewControllerViewModel: HomeViewControllerViewModelType,
  HomeViewControllerViewModelInputs,
HomeViewControllerViewModelOutputs {
  
  private let disposeBag = DisposeBag()
  
  public var inputs: HomeViewControllerViewModelInputs { return self }
  public var outputs: HomeViewControllerViewModelOutputs { return self }

  public init() {
    shop = Observable
      .combineLatest(viewWillAppearProperty, Shop.getOrCreate())
      .take(1)
      .map { $1 }
      .share(replay: 1)
    productAdded = productAddedAtProperty.productsWithAssociatedIndex()
    productEdited = productEditedAtProperty.productsWithAssociatedIndex()
    productDeleted = productDeletedAtProperty.productsWithAssociatedIndex()

    let productsUpdated = Observable.merge(
      productAdded.map { _ in () },
      productEdited.map { _ in () },
      productDeleted.map { _ in () }
    )

    shouldStartProductCreation = Observable
      .merge(productsCarouselDidTapAddProperty, addProductButtonPressedProperty)
      .flatMap { Shop.getOrCreate() }

    let product = Observable
      .merge(productsCarouselDidTapEditProductProperty)

    shouldEditProduct = product
      .flatMap { product in
        Shop.getOrCreate().map {
          (product.editProduct, $0)
        }
    }
    shouldPopProductEdition = productEditionPropDidGoBackProp
    
    shouldShowShareDialog = Observable
      .merge(productsCarouselDidTapShareWithURLProperty)
      .unwrap()
    
    shouldPreviewProduct = Observable
      .merge(
        productsCarouselDidTapProductWithUrlProperty,
        productsCarouselDidTapPreviewWithURLProperty
      )
      .unwrap()

    shouldShowPaypalConnect = paypalStatusTappedProperty
      .map { _ in AppEnvironment.current.userDefaults.shop }
      .unwrap()

    paypalStatusVisible = Observable.merge(
      viewWillAppearProperty,
      updatePaypalStatusProperty,
      productsUpdated
      )
      .map {
        let product = AppEnvironment.current.userDefaults.shop?.conf?.products ?? []
        if AppEnvironment.current.apiService.session == nil && product.isEmpty == false {
          return true
        }
        return false
    }

    shopEdited = shopEditedProp.flatMap { _ in Shop.getOrCreate() }
    shopUpdated = shopUpdatedProp.flatMap { _ in Shop.getOrCreate() }
    shouldPopShopEdition = shopEditionPropDidGoBackProp

    shouldPreviewShop = shopHeaderTappedProp
      .flatMap { Shop.getOrCreate() }
      .map { URL(string: "https://" + $0.domain) }
      .unwrap()

    shouldEditShop = shopHeaderSettingsTappedProp.flatMap { _ in
      return Shop.getOrCreate().map { $0.editShop }
    }

    shouldShowEmptyState = Observable
      .merge(shop.map { _ in () }, productsUpdated)
      .map { _ in (AppEnvironment.current.userDefaults.shop?.conf?.products ?? []).isEmpty }

    shouldShowIntercomButton = Observable.merge(
      viewDidAppearProperty.map { return true },
      viewWillDisappearProperty.map { return false }
    )

    shouldShowIntercomWindow = intercomButtonPressedProperty

    productsCarouselDidTapAddProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackOpenedCreateProduct(context: .homeProductCard) }
      .disposed(by: disposeBag)
    
    addProductButtonPressedProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackOpenedCreateProduct(context: .homeEmptyState) }
      .disposed(by: disposeBag)
    
    productsCarouselDidTapEditProductProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackOpenedEditProduct(context: .cardMenu) }
      .disposed(by: disposeBag)
    
    productsCarouselDidTapShareWithURLProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackOpenedShareProductDialog(context: .cardMenu) }
      .disposed(by: disposeBag)

    productsCarouselDidTapProductWithUrlProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackPreviewedProduct(context: .homeProductCard) }
      .disposed(by: disposeBag)

    productsCarouselDidTapPreviewWithURLProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackPreviewedProduct(context: .cardMenu) }
      .disposed(by: disposeBag)

    paypalStatusTappedProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackOpenedPaypalConnect() }
      .disposed(by: disposeBag)

    intercomButtonPressedProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackOpenedIntercom() }
      .disposed(by: disposeBag)

    shareDidCompleteProperty
      .skipWhile({ $0.1 == false })
      .subscribe(onNext: {
        AppEnvironment.current.analytics.trackSharedProduct(shareType: $0.0)
      })
      .disposed(by: disposeBag)

    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedHome() }
      .disposed(by: disposeBag)

    shop.observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        guard let `self` = self else { return }
        updateShopFromAPI(shop: $0, ps: self.shopUpdatedProp)
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Inputs
  
  private let addProductButtonPressedProperty = PublishSubject<Void>()
  public func addProductButtonPressed() {
    self.addProductButtonPressedProperty.onNext(())
  }

  private let intercomButtonPressedProperty = PublishSubject<Void>()
  public func intercomButtonPressed() {
    self.intercomButtonPressedProperty.onNext(())
  }
  
  private let productAddedAtProperty = PublishSubject<Int>()
  public func productAddedAt(index: Int) {
    self.productAddedAtProperty.onNext(index)
  }
  
  private let productEditedAtProperty = PublishSubject<Int>()
  public func productEditedAt(index: Int) {
    self.productEditedAtProperty.onNext(index)
  }

  private let productDeletedAtProperty = PublishSubject<Int>()
  public func productDeletedAt(index: Int) {
    self.productDeletedAtProperty.onNext(index)
  }

  private let shopEditedProp = PublishSubject<Shop>()
  public func shopEdited(_ shop: Shop) {
    self.shopEditedProp.onNext(shop)
  }

  private let shopUpdatedProp = PublishSubject<Shop>()
  public func shopUpdated(_ shop: Shop) {
    self.shopUpdatedProp.onNext(shop)
  }

  private let productEditionPropDidGoBackProp = PublishSubject<Void>()
  public func productEditionPropDidGoBack() {
    self.productEditionPropDidGoBackProp.onNext(())
  }

  private let shopEditionPropDidGoBackProp = PublishSubject<Void>()
  public func shopEditionPropDidGoBack() {
    self.shopEditionPropDidGoBackProp.onNext(())
  }
  
  private let focusOnProductProperty = PublishSubject<Product?>()
  public func focusOnProduct(_ product: Product?) {
    self.focusOnProductProperty.onNext(product)
  }

  private let viewWillAppearProperty = PublishSubject<Void>()
  public func viewWillAppear() {
    self.viewWillAppearProperty.onNext(())
  }

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  private let viewWillDisappearProperty = PublishSubject<Void>()
  public func viewWillDisappear() {
    self.viewWillDisappearProperty.onNext(())
  }

  private let paypalStatusTappedProperty = PublishSubject<Void>()
  public func paypalStatusTapped() {
    self.paypalStatusTappedProperty.onNext(())
  }

  private let updatePaypalStatusProperty = PublishSubject<Void>()
  public func updatePaypalStatus() {
    updatePaypalStatusProperty.onNext(())
  }
  
  private let productsCarouselDidTapEditProductProperty = PublishSubject<Product>()
  public func productsCarouselDidTapEditProduct(_ product: Product) {
    self.productsCarouselDidTapEditProductProperty.onNext(product)
  }
  
  private let productsCarouselDidTapPreviewWithURLProperty = PublishSubject<URL?>()
  public func productsCarouselDidTapPreviewWithURL(_ url: URL?) {
    self.productsCarouselDidTapPreviewWithURLProperty.onNext(url)
  }
  
  private let productsCarouselDidTapShareWithURLProperty = PublishSubject<URL?>()
  public func productsCarouselDidTapShareWithURL(_ url: URL?) {
    self.productsCarouselDidTapShareWithURLProperty.onNext(url)
  }
  
  private let productsCarouselDidTapAddProperty = PublishSubject<Void>()
  public func productsCarouselDidTapAdd() {
    self.productsCarouselDidTapAddProperty.onNext(())
  }

  private let productsCarouselDidTapProductWithUrlProperty = PublishSubject<URL?>()
  public func productsCarouselDidTapProductWithUrl(_ url: URL?) {
    self.productsCarouselDidTapProductWithUrlProperty.onNext(url)
  }

  private typealias ShareCompletionWithItemsHandler = (UIActivity.ActivityType?, Bool, [Any]?, Error?)
  private let shareDidCompleteProperty = PublishSubject<ShareCompletionWithItemsHandler>()
  public func shareDidComplete(activityType: UIActivity.ActivityType?,
                               completed: Bool,
                               returnedItems: [Any]?,
                               activityError: Error?) {
    self.shareDidCompleteProperty.onNext((activityType, completed, returnedItems, activityError))
  }

  private let shopHeaderTappedProp = PublishSubject<Void>()
  public func shopHeaderTapped() {
    self.shopHeaderTappedProp.onNext(())
  }

  private let shopHeaderSettingsTappedProp = PublishSubject<Void>()
  public func shopHeaderSettingsTapped() {
    self.shopHeaderSettingsTappedProp.onNext(())
  }
  
  // MARK: - Outputs
  
  public var shop: Observable<Shop>
  public var productAdded: Observable<([Product], Int)>
  public var productEdited: Observable<([Product], Int)>
  public var productDeleted: Observable<([Product], Int)>
  public var shouldStartProductCreation: Observable<Shop>
  public var shouldEditProduct: Observable<(EditProduct, Shop)>
  public var shouldShowShareDialog: Observable<URL>
  public var paypalStatusVisible: Observable<Bool>
  public var shouldPreviewProduct: Observable<URL>
  public var shouldShowPaypalConnect: Observable<Shop>
  public var shouldShowEmptyState: Observable<Bool>
  public var shouldPreviewShop: Observable<URL>
  public var shouldEditShop: Observable<EditShop>
  public var shouldPopShopEdition: Observable<Void>
  public var shouldPopProductEdition: Observable<Void>
  public var shopEdited: Observable<Shop>
  public var shopUpdated: Observable<Shop>
  public var shouldShowIntercomButton: Observable<Bool>
  public var shouldShowIntercomWindow: Observable<Void>
}

extension ObservableType where E == Int {
  func productsWithAssociatedIndex() -> Observable<([Product], Int)> {
    return map { index in
      guard let products = AppEnvironment.current.userDefaults.shop?.conf?.products,
        products.isEmpty == false else {
          return ([], 0)
      }
      return (products, index)
    }
  }
}

private func updateShopFromAPI(shop: Shop, ps: PublishSubject<Shop>) {
  _ = AppEnvironment.current.apiService
    .getShop(shopId: shop.id)
    .map {
      AppEnvironment.current.userDefaults.shop = $0
      AppEnvironment.current.analytics.set(shop: $0)
      return $0
    }.subscribe(onNext: {
      ps.onNext($0)
    })
}
