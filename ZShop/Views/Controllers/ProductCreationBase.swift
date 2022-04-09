import UIKit
import ZSLib

protocol ProductCreationBaseDelegate: class {
  func didSubmitWith(step: ProductCreationStep)
  func didGoBack()
  func didDismiss(_ completion: ((Bool) -> Void)?)
}

internal class ProductCreationBase: UIViewController {

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
  }
  
  weak var delegate: ProductCreationBaseDelegate?
  
  // MARK: - Init
  
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
  }
  
  // MARK: - Events
  
  @objc internal func closeButtonPressed() {
    self.delegate?.didDismiss(nil)
  }
}
