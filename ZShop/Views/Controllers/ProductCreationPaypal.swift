import RxCocoa
import RxSwift
import SafariServices
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductCreationPaypal: ProductCreationBase {
  private let viewModel: ProductCreationPaypalViewModelType = ProductCreationPaypalViewModel()
  private let disposeBag = DisposeBag()
  
  private let paypalComponent = PaypalComponent()
  
  @IBOutlet weak var backButton: FloatButton!
  @IBOutlet weak var paypalButton: FloatButton!
  @IBOutlet weak var skipButton: UIButton!
  
  // MARK: - Init
  
  internal static func configuredWith(shop: Shop) -> ProductCreationPaypal {
    let vc = Storyboard.ProductCreationPaypal.instantiate(ProductCreationPaypal.self)
    vc.paypalComponent.configureWith(shop: shop)
    vc.paypalComponent.hostViewController = vc
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    titleLabel.text = NSLocalizedString(
      "product_creation.paypal.title",
      value: "💵 Connect your PayPal account to start getting payments",
      comment: "Title of the page where the user can connect to PayPal.")
    
    backButton.do {
      let size = CGSize(width: 22, height: 22)
      let leftArrowNormal =
        image(named: "left-arrow", tintColor: .white)?.scaled(to: size)
      let leftArrowHighlighted =
        image(named: "left-arrow", tintColor: UIColor.white.withBrightnessDelta(-0.05))?.scaled(to: size)
      $0.setImage(leftArrowNormal, for: .normal)
      $0.setImage(leftArrowHighlighted, for: .highlighted)
      $0.sizeToFit()
      $0.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
      _ = $0 |> grayFloatButtonStyle <> squareFloatButtonStyle
    }
    
    let paypalLogoAttachment = NSTextAttachment().then {
      $0.image = image(named: "paypal-logo")
      $0.bounds = .init(x: 0, y: -4, width: 71, height: 20)
    }
    
    paypalButton.do {
      let title = NSLocalizedString(
        "product_creation.paypal.paypal_button.title",
        value: "Connect with {{paypal}}",
        comment: "Title of the button which opens paypal connect view.")
      
      let range = NSRange(location: 0, length: title.count)
      let attributedString = NSMutableAttributedString(string: title)
      attributedString.addAttributes([.foregroundColor: UIColor.white], range: range)
      
      if let paypalRange = title.range(of: "{{paypal}}") {
        let nsrange = NSRange(paypalRange, in: title)
        attributedString.replaceCharacters(
          in: nsrange,
          with: NSAttributedString(attachment: paypalLogoAttachment)
        )
      }
      
      $0.setAttributedTitle(attributedString, for: .normal)
      $0.sizeToFit()
      $0.addTarget(self, action: #selector(paypalButtonPressed), for: .touchUpInside)
      _ = $0 |> paypalFloatButtonStyle
    }
    
    skipButton.do {
      let title = NSLocalizedString(
        "product_creation.paypal.skip_button.title",
        value: "Setup later",
        comment: "Title of the button to skip paypal login at the end of the product creation.")
      $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
      $0.setTitle(title, for: .normal)
      $0.setTitleColor(UIColor.zs_black.withBrightnessDelta(0.2), for: .normal)
      $0.setBackgroundColor(.clear, for: .normal)
      $0.setBackgroundColor(UIColor.white.withBrightnessDelta(-0.05), for: .highlighted)
      $0.contentEdgeInsets = .init(top: 6, left: 10, bottom: 6, right: 10)
      $0.sizeToFit()
      $0.layer.masksToBounds = true
      $0.addTarget(self, action: #selector(skipButtonPressed), for: .touchUpInside)
    }
    
    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }
  
  override func bindViewModel() {
    super.bindViewModel()
    
    viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe (onNext: { [weak self] _ in
        self?.delegate?.didDismiss(nil)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldGoToNext
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] _ in
        self?.goToNext()
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldGoToPrevious
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.didGoBack()
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldSkip
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.delegate?.didSubmitWith(step: .paypal)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldStartPaypalConnect
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.paypalComponent.startPaypalAuth()
      })
      .disposed(by: disposeBag)
    
    paypalComponent.viewModel.outputs.paypalConnectDidSucceed
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.viewModel.inputs.paypalConnectDidSucceed()
      })
      .disposed(by: disposeBag)
    
    paypalComponent.viewModel.outputs.paypalConnectDidFail
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.viewModel.inputs.paypalConnectDidFail($0)
      })
      .disposed(by: disposeBag)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    skipButton.layer.cornerRadius = skipButton.bounds.height / 2
  }
  
  // MARK: - Events
  
  @objc internal func backButtonPressed(_ sender: UIButton) {
    viewModel.inputs.backButtonPressed()
  }
  
  @objc internal func paypalButtonPressed(_ sender: UIButton) {
    viewModel.inputs.paypalButtonPressed()
  }
  
  @objc override internal func closeButtonPressed() {
    viewModel.inputs.closeButtonPressed()
  }
  
  @objc internal func skipButtonPressed(_ sender: UIButton) {
    viewModel.inputs.skipButtonPressed()
  }
  
  // MARK: - Flow
  
  private func goToNext() {
    delegate?.didSubmitWith(step: .paypal)
  }
  
  private func didGoBack() {
    delegate?.didGoBack()
  }
}
