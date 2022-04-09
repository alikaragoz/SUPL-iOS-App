import RxCocoa
import RxSwift
import SafariServices
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class PaypalConnect: UIViewController {
  private let viewModel: PaypalConnectViewModelType = PaypalConnectViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case success
    case close
  }
  internal var callback: ((Callback) -> Void)?
  
  private let paypalComponent = PaypalComponent()

  @IBOutlet weak var paypalButton: FloatButton!

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
      "paypal_connect.title",
      value: "💵 Connect your PayPal account to start getting payments",
      comment: "Title of the page where the user can connect to PayPal.")
  }
  
  // MARK: - Init
  
  internal static func configuredWith(shop: Shop) -> PaypalConnect {
    let vc = Storyboard.PaypalConnect.instantiate(PaypalConnect.self)
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
    
    let paypalLogoAttachment = NSTextAttachment().then {
      $0.image = image(named: "paypal-logo")
      $0.bounds = .init(x: 0, y: -4, width: 71, height: 20)
    }
    
    paypalButton.do {
      let title = NSLocalizedString(
        "paypal_connect.paypal_button.title",
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
    
    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }
  
  override func bindViewModel() {
    super.bindViewModel()
    
    viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe (onNext: { [weak self] _ in
        self?.callback?(.close)
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
        self?.callback?(.success)
      })
      .disposed(by: disposeBag)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }
  
  // MARK: - Events
  
  @objc internal func paypalButtonPressed(_ sender: UIButton) {
    viewModel.inputs.paypalButtonPressed()
  }
  
  @objc internal func closeButtonPressed() {
    viewModel.inputs.closeButtonPressed()
  }
}
