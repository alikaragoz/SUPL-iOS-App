import FBSDKCoreKit
import Intercom
import UIKit
import RxCocoa
import RxSwift
import SafariServices
import ZSAPI
import ZSLib
import ZSPrelude

public final class HomeViewController: UIViewController {
  private let viewModel: HomeViewControllerViewModelType = HomeViewControllerViewModel()
  private let disposeBag = DisposeBag()
  
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var mainStackView: UIStackView!
  @IBOutlet weak var shopHeaderStackView: UIStackView!
  @IBOutlet weak var paypalStatusStackView: UIStackView!
  @IBOutlet weak var productsCarouselStackView: UIStackView!
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var emptyLabel: UILabel!
  @IBOutlet weak var addProductButton: FloatButton!
  
  let homeShopHeader = HomeShopHeader()
  let paypalStatus = PaypalStatusView()
  let productsCarousel = ProductsCarousel()
  var productCreationCoordinator: ProductCreationCoordinator?
  var productEdition: ProductEdition?
  var shopEdition: ShopEdition?
  
  var productsCarouselHeightConstraint: NSLayoutConstraint?
  
  let intercomButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let size = CGSize(width: 26, height: 26)
    let normalImage = image(named: "intercom", tintColor: .white)?.scaled(to: size)
    let highlightedImage =
      image(named: "intercom", tintColor: UIColor.white.withBrightnessDelta(-0.05))?.scaled(to: size)
    $0.setImage(normalImage, for: .normal)
    $0.setImage(highlightedImage, for: .highlighted)
    $0.sizeToFit()
    _ = $0 |> blackFloatButtonStyle <> squareFloatButtonStyle
  }
  
  // MARK: - Init
  
  public static func instance() -> HomeViewController {
    let vc = Storyboard.HomeViewController.instantiate(HomeViewController.self)
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
  
  // MARK: - UIViewController
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    title = NSLocalizedString(
      "home.title",
      value: "Your Shop",
      comment: "Title of the home")
    
    emptyView.backgroundColor = .zs_empty_view_gray
    
    addProductButton.do {
      let title = NSLocalizedString(
        "home.empty.add_product_button.title",
        value: "Add a product",
        comment: "Title of the button which start the product creation flow.")
      $0.setTitle(title, for: .normal)
      $0.sizeToFit()
      $0.addTarget(self, action: #selector(addProductButtonPressed), for: .touchUpInside)
      _ = $0 |> greenFloatButtonStyle
    }
    
    intercomButton.do {
      $0.addTarget(self, action: #selector(intercomButtonPressed), for: .touchUpInside)
      view.addSubview($0)
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
      $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
    }
    
    emptyLabel.do {
      let title = NSLocalizedString(
        "home.empty.title",
        value: "You don't have any products yet",
        comment: "Title of the label which says we don't have any products yet.")
      $0.text = title
      $0.font = .systemFont(ofSize: 32, weight: .bold)
      $0.textAlignment = .center
      $0.textColor = UIColor.hex(0xD8D8D8)
      $0.numberOfLines = 0
    }
    
    scrollView.do {
      $0.showsHorizontalScrollIndicator = false
      $0.alwaysBounceVertical = true
    }
    
    shopHeaderStackView.do {
      $0.layoutMargins = .init(top: 20, left: 20, bottom: 0, right: 20)
      $0.isLayoutMarginsRelativeArrangement = true
    }
    
    paypalStatusStackView.do {
      $0.layoutMargins = .init(top: 20, left: 20, bottom: 20, right: 20)
      $0.isLayoutMarginsRelativeArrangement = true
    }
    
    paypalStatus.do {
      paypalStatusStackView.addArrangedSubview($0)
      $0.callback = paypalStatusCallback
    }
    
    homeShopHeader.do { [weak self] in
      shopHeaderStackView.addArrangedSubview($0)
      $0.callback = self?.shopHeaderCallback
    }
    
    productsCarousel.do {
      $0.delegate = self
      addChild($0)
      productsCarouselStackView.addArrangedSubview($0.view)
      $0.didMove(toParent: self)
    }
    
    // layout
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }
  
  override public func bindViewModel() {
    super.bindViewModel()
    
    viewModel.outputs.shouldShowEmptyState
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.emptyView.isHidden = !$0
        self?.scrollView.isHidden = $0
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shop
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        let products = $0.conf?.products ?? []
        self?.productsCarousel.setProducts(products)
        self?.productsCarousel.moveToCurrentProduct()
        self?.homeShopHeader.configureWith(shop: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.productAdded
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.productsCarousel.addProduct(products: $0.0, index: $0.1)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.productEdited
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.productsCarousel.editProduct(products: $0.0, index: $0.1)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.productDeleted
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.productsCarousel.deleteProduct(products: $0.0, index: $0.1)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldStartProductCreation
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToCreation(shop: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldEditProduct
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToEdit(editProduct: $0, shop: $1)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldShowShareDialog
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToShare(url: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldPreviewProduct
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToSafariBrowser(url: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldShowPaypalConnect
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToPaypalConnect(shop: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.paypalStatusVisible
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.paypalStatus.isHidden = !$0
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldPreviewShop
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToSafariBrowser(url: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldEditShop
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToShopEdition(editShop: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shopEdited
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.navigationController?.popToRootViewController(animated: true)
        self?.shopEdition = nil
        self?.homeShopHeader.configureWith(shop: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shopUpdated
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        let products = $0.conf?.products ?? []
        self?.productsCarousel.setProducts(products)
        self?.productsCarousel.moveToCurrentProduct()
        self?.homeShopHeader.configureWith(shop: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldPopShopEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.navigationController?.popToRootViewController(animated: true)
        self?.shopEdition = nil
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldPopProductEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.navigationController?.popToRootViewController(animated: true)
        self?.productEdition = nil
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldShowIntercomButton
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.adjustInterButtonWithVisibleState(visible: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldShowIntercomWindow
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: {
        NotificationCenter.default.post(
          name: Notification.Name.zs_showNotificationsDialog,
          object: nil,
          userInfo: nil
        )
        Intercom.presentMessenger()
      })
      .disposed(by: disposeBag)
  }
  
  override public func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.inputs.viewWillAppear()
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }
  
  override public func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewModel.inputs.viewWillDisappear()
  }
  
  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if productsCarouselHeightConstraint == nil {
      let size = productsCarousel.estimatedSize()
      productsCarouselHeightConstraint = productsCarousel.view.heightAnchor
        .constraint(equalToConstant: size.height)
      productsCarouselHeightConstraint?.isActive = true
    }
  }
  
  // MARK: - Events
  
  @objc internal func addProductButtonPressed() {
    viewModel.inputs.addProductButtonPressed()
  }
  
  @objc internal func intercomButtonPressed() {
    viewModel.inputs.intercomButtonPressed()
  }
  
  internal func adjustInterButtonWithVisibleState(visible: Bool) {
    UIView.animate(withDuration: 0.15, animations: {
      self.intercomButton.alpha = visible ? 1 : 0
      self.intercomButton.transform = CGAffineTransform(
        scaleX: visible ? 1.0 : 0.8,
        y: visible ? 1.0 : 0.8
      )
    })
  }
  
  // MARK: - Flow
  
  private func goToCreation(shop: Shop) {
    let coordinator = ProductCreationCoordinator(shop: shop, rootViewController: self)
    coordinator.start()
    self.productCreationCoordinator = coordinator
    self.productCreationCoordinator?.callback = productCreationCoordinatorCallback
  }
  
  private func goToSafariBrowser(url: URL) {
    let controller = SFSafariViewController(url: url)
    self.present(controller, animated: true, completion: nil)
  }
  
  private func goToShare(url: URL) {
    let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    controller.modalPresentationStyle = .overFullScreen
    controller.completionWithItemsHandler = viewModel.inputs.shareDidComplete
    self.present(controller, animated: true, completion: nil)
  }
  
  private func goToEdit(editProduct: EditProduct, shop: Shop) {
    let productEdition = ProductEdition.configuredWith(shop: shop, editProduct: editProduct)
    productEdition.callback = productEditionCallback
    self.navigationController?.pushViewController(productEdition, animated: true)
    self.productEdition = productEdition
  }
  
  private func goToShopEdition(editShop: EditShop) {
    let shopEdition = ShopEdition.configuredWith(editShop: editShop)
    shopEdition.callback = shopEditionCallback
    self.navigationController?.pushViewController(shopEdition, animated: true)
    self.shopEdition = shopEdition
  }
  
  private func goToPaypalConnect(shop: Shop) {
    let paypalConnect = PaypalConnect.configuredWith(shop: shop)
    paypalConnect.callback = { [weak self] in
      switch $0 {
      case .success:
        self?.viewModel.inputs.updatePaypalStatus()
        paypalConnect.dismiss(animated: true, completion: nil)
      case .close:
        paypalConnect.dismiss(animated: true, completion: nil)
      }
    }
    self.present(paypalConnect, animated: true, completion: nil)
  }
}

// MARK: - PayPal Status

extension HomeViewController {
  private func paypalStatusCallback(_ callback: PaypalStatusView.Callback) {
    switch callback {
    case .tapped:
      viewModel.inputs.paypalStatusTapped()
    }
  }
}

// MARK: - Header

extension HomeViewController {
  private func shopHeaderCallback(_ callback: HomeShopHeader.Callback) {
    switch callback {
    case .viewTapped:
      viewModel.inputs.shopHeaderTapped()
    case .settingsTapped:
      viewModel.inputs.shopHeaderSettingsTapped()
    }
  }
}

// MARK: - ProductsCarouselDelegate

extension HomeViewController: ProductsCarouselDelegate {
  public func productsCarouselDidFocusOnProduct(_ product: Product?) {
    viewModel.inputs.focusOnProduct(product)
  }
  
  public func productsCarouselDidTapAdd() {
    viewModel.inputs.productsCarouselDidTapAdd()
  }
  
  public func productsCarouselDidTapEditProduct(_ product: Product) {
    viewModel.inputs.productsCarouselDidTapEditProduct(product)
  }
  
  public func productsCarouselDidTapPreviewWithURL(_ url: URL?) {
    viewModel.inputs.productsCarouselDidTapPreviewWithURL(url)
  }
  
  public func productsCarouselDidTapShareWithURL(_ url: URL?) {
    viewModel.inputs.productsCarouselDidTapShareWithURL(url)
  }
  
  public func productsCarouselDidTapProductWithUrl(_ url: URL?) {
    viewModel.inputs.productsCarouselDidTapProductWithUrl(url)
  }
}

// MARK: - Product Updates

extension HomeViewController {
  private func productCreationCoordinatorCallback(_ callback: ProductCreationCoordinator.Callback) {
    switch callback {
    case let .update(shopChange):
      productCreationCoordinator = nil
      handleShopChanges(shopChange)
    case .stop:
      productCreationCoordinator = nil
    }
  }
  
  private func productEditionCallback(_ callback: ProductEdition.Callback) {
    switch callback {
    case let .update(shopChange):
      handleShopChanges(shopChange)
    case .back:
      viewModel.inputs.productEditionPropDidGoBack()
    }
  }
  
  private func handleShopChanges(_ shopChange: ShopChange) {
    navigationController?.popToRootViewController(animated: true)
    productEdition = nil
    
    switch shopChange {
    case let .add(index):
      viewModel.inputs.productAddedAt(index: index)
    case let .update(index):
      viewModel.inputs.productEditedAt(index: index)
    case let .delete(index):
      viewModel.inputs.productDeletedAt(index: index)
    }
  }
}

// MARK: - Shop Updates

extension HomeViewController {
  private func shopEditionCallback(_ callback: ShopEdition.Callback) {
    switch callback {
    case let .save(shop):
      viewModel.inputs.shopEdited(shop)
    case .back:
      viewModel.inputs.shopEditionPropDidGoBack()
    }
  }
}
