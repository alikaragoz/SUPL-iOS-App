import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductCreationPrice: UIViewController {
  private let viewModel: ProductCreationPriceViewModelType = ProductCreationPriceViewModel()
  private(set) var editPriceComponent: EditPriceComponent?
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case next(PriceInfo)
    case back
    case close(((Bool) -> Void)?)
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
      "product_creation.price.title",
      value: "💰 What is the price of your product?",
      comment: "Title of the page where we ask the user for the price of the product he is creating.")
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

  let nextButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let size = CGSize(width: 22, height: 22)
    let rightArrowNormal =
      image(named: "right-arrow", tintColor: .white)?.scaled(to: size)
    let rightArrowHighlighted =
      image(named: "right-arrow", tintColor: UIColor.white.withBrightnessDelta(-0.05))?.scaled(to: size)
    $0.setImage(rightArrowNormal, for: .normal)
    $0.setImage(rightArrowHighlighted, for: .highlighted)
    $0.sizeToFit()
    _ = $0 |> greenFloatButtonStyle <> squareFloatButtonStyle
  }

  let container = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - Init

  internal static func configuredWith(priceInfo: PriceInfo?) -> ProductCreationPrice {
    let vc = ProductCreationPrice(nibName: nil, bundle: nil)
    vc.configureWith(priceInfo: priceInfo)
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

  internal func configureWith(priceInfo: PriceInfo?) {
    editPriceComponent = EditPriceComponent.configuredWith(priceInfo: priceInfo)
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
      $0.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    if let editNameComponent = self.editPriceComponent {
      addSubController(editNameComponent)
    }

    if let containerView = editPriceComponent?.containerView {
      backButton.do {
        $0.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        containerView.addSubview($0)
        $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        $0.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 20).isActive = true
        $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
      }

      nextButton.do {
        $0.addTarget(self, action: #selector(nextButtonPressed), for: .touchUpInside)
        containerView.addSubview($0)
        $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        $0.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -20).isActive = true
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

    editPriceComponent?.viewModel.outputs.shouldSubmit
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.next($0))
      })
      .disposed(by: disposeBag)

    editPriceComponent?.viewModel.outputs.isValid
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] enabled in
        self?.nextButton.isEnabled = enabled
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
    callback?(.close({ [weak self] didDismiss in
      if didDismiss {
        self?.editPriceComponent?.viewModel.inputs.didDismiss()
      }
    }))
  }

  @objc internal func backButtonPressed(_ sender: UIButton) {
    callback?(.back)
  }

  @objc internal func nextButtonPressed() {
    editPriceComponent?.viewModel.inputs.submitButtonPressed()
  }
}
