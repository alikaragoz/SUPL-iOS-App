// swiftlint:disable line_length
import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductEdition: UIViewController {
  private let viewModel: ProductEditionViewModelType = ProductEditionViewModel()
  private let disposeBag = DisposeBag()

  private var productSaveViewModel: ProductSaveViewModelType?
  private var productEditionComponent: ProductEditionComponent?
  private var inPlaceLoader: InPlaceLoader?

  internal enum Callback {
    case update(ShopChange)
    case back
  }
  internal var callback: ((Callback) -> Void)?

  let moreButton = UIBarButtonItem().then {
    $0.style = .done
    $0.title = NSLocalizedString(
      "edit_product.more_button.title",
      value: "More",
      comment: "Title of the button in the navigation bar which presents more options.")
  }

  let saveButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let saveTitle = NSLocalizedString(
      "edit_product.save_button.title",
      value: "Save",
      comment: "Title of the button to save the changes in the edit page")
    $0.setTitle(saveTitle, for: .normal)
    $0.sizeToFit()
    _ = $0 |> greenFloatButtonStyle
  }

  let container = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - Init

  internal static func configuredWith(shop: Shop, editProduct: EditProduct) -> ProductEdition {
    let vc = ProductEdition(nibName: nil, bundle: nil)
    vc.configureWith(shop: shop, editProduct: editProduct)
    return vc
  }

  convenience init() {
    self.init(nibName: nil, bundle: nil)
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: - Configuration

  internal func configureWith(shop: Shop, editProduct: EditProduct) {
    viewModel.inputs.configureWith(shop: shop, editProduct: editProduct)
    productEditionComponent = ProductEditionComponent.configuredWith(shop: shop, editProduct: editProduct)
    productEditionComponent?.viewModel.inputs.setMode(.edition)
    productEditionComponent?.callback = { [weak self] in
      switch $0 {
      case let .save(editProduct):
        guard let `self` = self else { return }
        self.save(.update(editProduct), shop: shop)
      }
    }
  }

  internal func save(_ type: ProductSaveType, shop: Shop) {
    let inPlaceLoader = InPlaceLoader()
    inPlaceLoader.hostViewController = self
    self.inPlaceLoader = inPlaceLoader
    inPlaceLoader.start()

    self.productSaveViewModel = ProductSaveViewModel()
    self.bindProductSaveViewModel()
    self.productSaveViewModel?.inputs.configureWith(shop: shop, saveType: type)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    self.do {
      $0.navigationItem.largeTitleDisplayMode = .never
      $0.view.backgroundColor = .white
      $0.title = NSLocalizedString(
        "edit_product.title",
        value: "Edit product",
        comment: "Title of the view where we can review and edit a product."
      )
    }

    container.do {
      view.addSubview($0)
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    if let productEditionComponent = self.productEditionComponent {
      addSubController(productEditionComponent)
    }

    moreButton.do {
      $0.target = self
      $0.action = #selector(moreButtonPressed)
      self.navigationItem.rightBarButtonItem = $0
    }

    saveButton.do {
      $0.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
      self.view.addSubview($0)
      $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
      $0.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func bindViewModel() {
    super.bindViewModel()

    productEditionComponent?.viewModel.outputs.isValid
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.saveButton.isEnabled = $0
      })
      .disposed(by: disposeBag)

    productEditionComponent?.viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.dismiss(withConfirm: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentMoreOptionsAlert
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentMoreOptions(isEnabled: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentDeleteConfirmationAlert
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] _ in
        self?.presentConfirmDelete()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldDeleteProduct
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.save(.delete($0.1), shop: $0.0)
      })
      .disposed(by: disposeBag)
  }

  private func bindProductSaveViewModel() {
    productSaveViewModel?.outputs.didSave
      .delay(0.8, scheduler: AppEnvironment.current.mainScheduler)
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] _, shopChange in
        self?.callback?(.update(shopChange))
      })
      .disposed(by: disposeBag)

    productSaveViewModel?.outputs.shouldCompleteLoader
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.inPlaceLoader?.complete()
      })
      .disposed(by: disposeBag)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: true)
  }

  // MARK: - Sub VCs

  func addSubController(_ controller: UIViewController) {
    controller.do {
      addChild($0)
      container.addSubview($0.view)
      $0.view.translatesAutoresizingMaskIntoConstraints = false
      $0.view.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
      $0.view.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
      $0.view.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
      $0.view.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
      $0.didMove(toParent: self)
    }
  }

  // MARK: - Dismiss

  private func dismiss(withConfirm confirmation: Bool) {

    let dismissAction = { [weak self] in
      self?.callback?(.back)
    }

    if confirmation == false {
      dismissAction()
    } else {
      let message = NSLocalizedString(
        "edit_product.exit_confirm.title",
        value: "Are you sure you want to quit? You will lose all your edits.",
        comment: "Title of alert to confirm if the user wants to quit the product edition.")

      let loseEditsActionTitle = NSLocalizedString(
        "edit_product.exit_confirm.lose_edits_title",
        value: "Lose Edits",
        comment: "Title of the button to confirm if the user wants to quit the product edition. This will lose his edits on the product")

      let cancelActionTitle = NSLocalizedString(
        "edit_product.exit_confirm.cancel_title",
        value: "Cancel",
        comment: "Title of the button to confirm if the user wants to quit the product edition. This will cancel the delete")

      let alert = UIAlertController.confirmationAlert(
        message: message,
        actionTitle: loseEditsActionTitle,
        cancelTitle: cancelActionTitle) { quit in
          if quit {
            dismissAction()
          }
      }
      self.navigationController?.present(alert, animated: true, completion: nil)
    }
  }

  // MARK: - More Options

  private func presentMoreOptions(isEnabled: Bool) {

    let deleteActionTitle = NSLocalizedString(
      "edit_product.more_options.delete_shop",
      value: "Delete",
      comment: "Title of the button to delete a product.")

    let cancelActionTitle = NSLocalizedString(
      "edit_product.more_options.cancel",
      value: "Cancel",
      comment: "Title of the button to cancel the more product action sheet.")

    let alertController = UIAlertController.universalActionSheet(title: nil, message: nil)

    let deleteAction = UIAlertAction(title: deleteActionTitle, style: .destructive) { [weak self] _ in
      self?.viewModel.inputs.deleteActionPressed()
    }
    alertController.addAction(deleteAction)

    let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
    alertController.addAction(cancelAction)

    self.navigationController?.present(alertController, animated: true, completion: nil)
  }

  private func presentConfirmDelete() {
    let message = NSLocalizedString(
      "edit_product.confirm_delete.title",
      value: "Are you sure you want to delete this product? This action is not reversible.",
      comment: "Title of alert to confirm if the user wants to delete the product.")

    let deleteActionTitle = NSLocalizedString(
      "edit_product.confirm_delete.delete",
      value: "Yes I'm sure",
      comment: "Title of the button to confirm if the user wants to delete the product. This will delete the current product")

    let cancelActionTitle = NSLocalizedString(
      "edit_product.confirm_delete.cancel",
      value: "Cancel",
      comment: "Title of the button to confirm if the user wants to quit the product. This will cancel the delete")

    let alert = UIAlertController.confirmationAlert(
      message: message,
      actionTitle: deleteActionTitle,
      cancelTitle: cancelActionTitle) { [weak self] delete in
        if delete {
          self?.viewModel.inputs.confirmedProductDelete()
        }
    }
    self.navigationController?.present(alert, animated: true, completion: nil)
  }

  // MARK: - Events

  @objc internal func saveButtonPressed() {
    productEditionComponent?.viewModel.inputs.submitButtonPressed()
  }

  @objc internal func moreButtonPressed() {
    self.viewModel.inputs.moreButtonPressed()
  }
}

extension ProductEdition {
  @objc override func shouldPopOnBackButton() -> Bool {
    productEditionComponent?.viewModel.inputs.didDismiss()
    return false
  }
}
