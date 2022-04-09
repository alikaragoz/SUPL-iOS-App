// swiftlint:disable line_length
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductCreationCoordinator {
  private let viewModel: ProductCreationCoordinatorViewModelType = ProductCreationCoordinatorViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case stop
    case update(ShopChange)
  }
  internal var callback: ((Callback) -> Void)?

  private weak var navigationController: UINavigationController?
  private(set) weak var rootViewController: UIViewController?

  // MARK: - Init
  
  init(shop: Shop, rootViewController: UIViewController) {
    self.rootViewController = rootViewController
    viewModel.inputs.configureWith(shop: shop)
    bindViewModel()
  }

  private func bindViewModel() {
    viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] (forceDismiss, callback) in
        if forceDismiss {
          callback?(true)
          self?.rootViewController?.dismiss(animated: true) { [weak self] in
            self?.callback?(.stop)
          }
        } else {
          self?.askForDismiss(callback)
        }
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldGoBack
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] _ in
        self?.navigationController?.popViewController(animated: true)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldNavigateToStep
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        switch $0 {
        case let .price(priceInfo):
          self?.shouldNavigateToPriceStep(priceInfo: priceInfo)
        case .picture:
          self?.shouldNavigateToPictures()
        case let .review(editProduct, shop):
          self?.shouldNavigateToReview(editProduct: editProduct, shop: shop)
        case let .paypal(shop):
          self?.shouldNavigateToPaypal(shop: shop)
        case let .save(editProduct, shop):
          self?.shouldNavigateToSave(editProduct: editProduct, shop: shop)
        case let .share(product):
          self?.shouldNavigateToShare(product: product)
        case let .end(shopChange):
          self?.shouldNavigateToEnd(shopChange: shopChange)
        }
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldShowNameStep
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentNameStepWith(creatorProduct: $0)
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Lifecycle
  
  func start() {
    viewModel.inputs.didStart()
  }
  
  // MARK: - Routes

  private func presentNameStepWith(creatorProduct: CreatorProduct) {
    let productCreationName = ProductCreationName.configuredWith(name: creatorProduct.name ?? "")
    productCreationName.callback = { [weak self] in
      switch $0 {
      case let .next(name):
        self?.viewModel.inputs.didSubmitWith(step: .name(name))
      case let .close(completion):
        self?.viewModel.inputs.didDismiss(completion)
      }
    }
    let navigationController = UINavigationController(rootViewController: productCreationName)
    navigationController.setNavigationBarHidden(true, animated: false)
    self.rootViewController?.present(navigationController, animated: true, completion: nil)
    self.navigationController = navigationController
  }
  
  private func shouldNavigateToPriceStep(priceInfo: PriceInfo?) {
    let productCreationPrice = ProductCreationPrice
      .configuredWith(priceInfo: priceInfo)
    productCreationPrice.callback = { [weak self] in
      switch $0 {
      case let .next(priceInfo):
        self?.viewModel.inputs.didSubmitWith(step: .price(priceInfo))
      case .back:
        self?.viewModel.inputs.didGoBack()
      case let .close(completion):
        self?.viewModel.inputs.didDismiss(completion)
      }
    }
    self.navigationController?.pushViewController(productCreationPrice, animated: true)
  }

  private func shouldNavigateToPictures() {
    let productCreationPicture = ProductCreationPicture.instance()
    productCreationPicture.delegate = self
    self.navigationController?.pushViewController(productCreationPicture, animated: true)
  }

  private func shouldNavigateToReview(editProduct: EditProduct, shop: Shop) {
    let productReview = ProductReview.configuredWith(shop: shop, editProduct: editProduct
    )
    
    productReview.callback = { [weak self] in
      switch $0 {
      case .close:
        self?.askForDismiss(nil)
      }
    }

    productReview.productEditionComponent?.callback = { [weak self] in
      switch $0 {
      case let .save(editProduct):
        self?.viewModel.inputs.didSubmitWith(step: .review(editProduct))
      }
    }
    self.navigationController?.pushViewController(productReview, animated: true)
  }

  private func shouldNavigateToPaypal(shop: Shop) {
    let productCreation = ProductCreationPaypal.configuredWith(shop: shop)
    productCreation.delegate = self
    self.navigationController?.pushViewController(productCreation, animated: true)
  }

  private func shouldNavigateToSave(editProduct: EditProduct, shop: Shop) {
    let productCreationSave = ProductCreationSave.configuredWith(shop: shop, editProduct: editProduct)
    productCreationSave.callback = { [weak self] in
      switch $0 {
      case let .saved(product, shopChange):
        self?.viewModel.inputs.didSubmitWith(step: .save(product, shopChange))
      case .back:
        self?.viewModel.inputs.didGoBack()
      case .close:
        self?.viewModel.inputs.didDismiss(nil)
      }
    }
    self.navigationController?.pushViewController(productCreationSave, animated: true)
  }

  private func shouldNavigateToShare(product: Product) {
    let productCreationShare = ProductCreationShare.configuredWith(product: product)
    productCreationShare.callback = { [weak self] in
      switch $0 {
      case let .next(product):
        self?.viewModel.inputs.didSubmitWith(step: .share(product))
      }
    }
    self.navigationController?.pushViewController(productCreationShare, animated: true)
  }

  private func shouldNavigateToEnd(shopChange: ShopChange) {
    self.rootViewController?.dismiss(animated: true) { [weak self] in
      self?.callback?(.update(shopChange))
    }
  }
}

extension ProductCreationCoordinator: ProductCreationBaseDelegate {
  func didSubmitWith(step: ProductCreationStep) {
    viewModel.inputs.didSubmitWith(step: step)
  }
  
  func didGoBack() {
    viewModel.inputs.didGoBack()
  }

  func didDismiss(_ completion: ((Bool) -> Void)?) {
    askForDismiss(completion)
  }

  func askForDismiss(_ completion: ((Bool) -> Void)?) {
    let message = NSLocalizedString(
      "product_creation.exit_confirm.title",
      value: "Are you sure you want to quit? This will delete the product.",
      comment: "Title of alert to confirm if the user wants to quit the product creation.")

    let deleteActionTitle = NSLocalizedString(
      "product_creation.exit_confirm.delete_title",
      value: "Delete Product",
      comment: "Title of the button to confirm if the user wants to quit the product creation. This will delete the current product")

    let cancelActionTitle = NSLocalizedString(
      "product_creation.exit_confirm.cancel_title",
      value: "Cancel",
      comment: "Title of the button to confirm if the user wants to quit the product creation. This will cancel the delete")

    let alert = UIAlertController.confirmationAlert(
      message: message,
      actionTitle: deleteActionTitle,
      cancelTitle: cancelActionTitle) { [weak self] quit in
        if quit {
          completion?(true)
          self?.rootViewController?.dismiss(animated: true) { [weak self] in
            self?.callback?(.stop)
          }
        } else {
          completion?(false)
        }
    }

    self.navigationController?.present(alert, animated: true, completion: nil)
  }
}
