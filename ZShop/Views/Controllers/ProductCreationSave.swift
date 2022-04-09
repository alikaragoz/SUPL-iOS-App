import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductCreationSave: UIViewController {
  private let viewModel: ProductCreationSaveViewModelType = ProductCreationSaveViewModel()
  private(set) var productSaveComponent: ProductSaveComponent?
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case saved(Product, ShopChange)
    case back
    case close
  }
  internal var callback: ((Callback) -> Void)?

  let closeButton = UIButton().then {
    let size = CGSize(width: 22, height: 22)
    let closeImageNormal =
      image(named: "remove", tintColor: .zs_light_gray)?.scaled(to: size)
    let closeImageHighlighted =
      image(named: "remove", tintColor: UIColor.zs_light_gray.withBrightnessDelta(0.05))?.scaled(to: size)
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.setImage(closeImageNormal, for: .normal)
    $0.setImage(closeImageHighlighted, for: .highlighted)
  }

  let backButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let size = CGSize(width: 22, height: 22)
    let leftArrowNormal =
      image(named: "left-arrow", tintColor: .white)?.scaled(to: size)
    let leftArrowHighlighted =
      image(named: "left-arrow", tintColor: UIColor.white.withBrightnessDelta(-0.05))?.scaled(to: size)
    $0.setImage(leftArrowNormal, for: .normal)
    $0.setImage(leftArrowHighlighted, for: .highlighted)
    $0.sizeToFit()
    _ = $0 |> grayFloatButtonStyle <> squareFloatButtonStyle
  }

  let container = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - Init

  internal static func configuredWith(shop: Shop, editProduct: EditProduct) -> ProductCreationSave {
    let vc = ProductCreationSave(nibName: nil, bundle: nil)
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
    productSaveComponent = ProductSaveComponent.configuredWith(
      shop: shop,
      saveType: .add(editProduct)
    )
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    container.do {
      view.addSubview($0)
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    closeButton.do {
      view.addSubview($0)
      $0.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor, multiplier: 1.0).isActive = true
      $0.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0).isActive = true
      $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0).isActive = true
      $0.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
    }

    if let productSaveComponent = self.productSaveComponent {
      addSubController(productSaveComponent)
    }

    if let containerView = productSaveComponent?.view {
      backButton.do {
        $0.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        containerView.addSubview($0)
        $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        $0.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20).isActive = true
        $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
      }
    }

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func bindViewModel() {
    super.bindViewModel()

    productSaveComponent?.viewModel.outputs.didSave
      .observeOn(AppEnvironment.current.mainScheduler)
      .delay(2.0, scheduler: AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.saved($0.0, $0.1))
      })
      .disposed(by: disposeBag)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
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

  // MARK: - Events

  @objc internal func closeButtonPressed() {
    callback?(.close)
  }

  @objc internal func backButtonPressed(_ sender: UIButton) {
    callback?(.back)
  }
}
