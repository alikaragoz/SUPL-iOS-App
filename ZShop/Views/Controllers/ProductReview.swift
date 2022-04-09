import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductReview: UIViewController {
  private let viewModel: ProductReviewViewModelType = ProductReviewViewModel()
  private(set) var productEditionComponent: ProductEditionComponent?
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case close
  }
  internal var callback: ((Callback) -> Void)?

  let closeButton = UIButton().then {
    let size = CGSize(width: 24, height: 24)
    let closeImageNormal =
      image(named: "remove", tintColor: .zs_light_gray)?.scaled(to: size)
    let closeImageHighlighted =
      image(named: "remove", tintColor: UIColor.zs_light_gray.withBrightnessDelta(0.05))?.scaled(to: size)
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.setImage(closeImageNormal, for: .normal)
    $0.setImage(closeImageHighlighted, for: .highlighted)
  }

  var saveButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let saveTitle = NSLocalizedString(
      "edit_product.save_button.title",
      value: "Save",
      comment: "Title of the button to save the changes in the edit page")
    $0.setTitle(saveTitle, for: .normal)
    $0.sizeToFit()
    _ = $0 |> greenFloatButtonStyle
  }

  let titleLabel = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.font = .systemFont(ofSize: 20, weight: .regular)
    $0.textColor = .zs_black
    $0.textAlignment = .center
    $0.numberOfLines = 2
    $0.adjustsFontSizeToFitWidth = true
    $0.minimumScaleFactor = 0.7
    $0.lineBreakMode = .byWordWrapping
    $0.text = NSLocalizedString(
      "review_product.title",
      value: "🔍 Review your product",
      comment: "Title of the view where we can review and edit a product."
    )
  }

  let container = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - Init

  internal static func configuredWith(shop: Shop, editProduct: EditProduct) -> ProductReview {
    let vc = ProductReview(nibName: nil, bundle: nil)
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
    productEditionComponent = ProductEditionComponent.configuredWith(shop: shop, editProduct: editProduct)
    productEditionComponent?.viewModel.inputs.setMode(.review)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    closeButton.do {
      view.addSubview($0)
      $0.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor, multiplier: 1.0).isActive = true
      $0.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0).isActive = true
      $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0).isActive = true
      $0.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
    }

    titleLabel.do {
      view.addSubview($0)
      $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0).isActive = true
      $0.leftAnchor.constraint(equalTo: closeButton.rightAnchor, constant: 10.0).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -60.0).isActive = true
      $0.sizeToFit()
    }

    container.do {
      view.insertSubview($0, belowSubview: closeButton)
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10.0).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    if let productEditionComponent = self.productEditionComponent {
      addSubController(productEditionComponent)
    }

    saveButton.do {
      $0.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
      self.view.addSubview($0)
      $0.bottomAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
      $0.centerXAnchor
        .constraint(equalTo: view.centerXAnchor).isActive = true
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

  @objc internal func saveButtonPressed() {
    productEditionComponent?.viewModel.inputs.submitButtonPressed()
  }

  @objc internal func closeButtonPressed() {
    callback?(.close)
  }
}
