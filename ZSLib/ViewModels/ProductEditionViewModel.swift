import Foundation
import RxSwift
import RxCocoa
import ZSAPI
import ZSPrelude

public protocol ProductEditionViewModelInputs {
  // call to configure with EditProduct
  func configureWith(shop: Shop, editProduct: EditProduct)

  // call when the view did appear
  func viewDidAppear()

  // call when the more button is pressed
  func moreButtonPressed()

  // call when the delete action is pressed in the action sheet
  func deleteActionPressed()

  // call when the product delete confirmation button is pressed
  func confirmedProductDelete()
}

public protocol ProductEditionViewModelOutputs {
  // emits when the more options alert should be presented
  var shouldPresentMoreOptionsAlert: Observable<Bool> { get }

  // emits when the delete confirmation alert should be presented
  var shouldPresentDeleteConfirmationAlert: Observable<Void> { get }

  // emits when the product should be deleted
  var shouldDeleteProduct: Observable<(Shop, EditProduct)> { get }
}

public protocol ProductEditionViewModelType {
  var inputs: ProductEditionViewModelInputs { get }
  var outputs: ProductEditionViewModelOutputs { get }
}

public class ProductEditionViewModel: ProductEditionViewModelType,
  ProductEditionViewModelInputs,
ProductEditionViewModelOutputs {

  public var inputs: ProductEditionViewModelInputs { return self }
  public var outputs: ProductEditionViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    let editProduct = configureEditProductProperty.unwrap().map { $0.editProduct }

    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedEditProduct() }
      .disposed(by: disposeBag)

    shouldPresentMoreOptionsAlert = moreButtonPressedProperty
      .withLatestFrom(editProduct)
      .map { editProduct in
        return !(editProduct.disabled ?? false)
    }

    shouldPresentDeleteConfirmationAlert = deleteActionPressedProperty
    shouldDeleteProduct = confirmedProductDeleteProperty
      .withLatestFrom(
        configureEditProductProperty
          .unwrap()
          .map { ($0.shop, $0.editProduct) }
    )
  }

  // MARK: - Inputs
  private typealias ConfigureParams = (shop: Shop, editProduct: EditProduct)
  private let configureEditProductProperty = BehaviorRelay<ConfigureParams?>(value: nil)
  public func configureWith(shop: Shop, editProduct: EditProduct) {
    self.configureEditProductProperty.accept((shop, editProduct))
  }

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  private let moreButtonPressedProperty = PublishSubject<Void>()
  public func moreButtonPressed() {
    self.moreButtonPressedProperty.onNext(())
  }

  private let deleteActionPressedProperty = PublishSubject<Void>()
  public func deleteActionPressed() {
    self.deleteActionPressedProperty.onNext(())
  }

  private let confirmedProductDeleteProperty = PublishSubject<Void>()
  public func confirmedProductDelete() {
    self.confirmedProductDeleteProperty.onNext(())
  }

  // MARK: - Outputs

  public var shouldPresentMoreOptionsAlert: Observable<Bool>
  public var shouldPresentDeleteConfirmationAlert: Observable<Void>
  public var shouldDeleteProduct: Observable<(Shop, EditProduct)>
}
