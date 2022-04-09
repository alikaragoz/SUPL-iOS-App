import UIKit
import ZSPrelude
import ZSLib

final public class PaypalStatusView: UIView {

  public enum Callback {
    case tapped
  }
  internal var callback: ((Callback) -> Void)?

  struct Constants {
    static let color: UIColor = .hex(0xFFA500)
  }

  private let title = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
    $0.textAlignment = .center
    $0.backgroundColor = .clear
    $0.numberOfLines = 0
    $0.textColor = Constants.color
    $0.text = NSLocalizedString(
      "paypal_status.title",
      value: "Connect your PayPal account to start getting payments",
      comment: "Title of the badge indicating status of Paypal") + " →"
  }

  private let warning = UIImageView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.image = image(named: "credit-card")
    $0.contentMode = .scaleAspectFit
    $0.backgroundColor = .clear
    $0.tintColor = Constants.color
  }

  // MARK: - Init

  public convenience init() {
    self.init(frame: .zero)
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }

  private func setup() {
    self.do {
      $0.backgroundColor = Constants.color.withAlphaComponent(0.15)
    }

    warning.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15.0).isActive = true
      $0.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 24).isActive = true
      $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
    }
    
    title.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 45.0).isActive = true
      $0.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -40.0).isActive = true
      $0.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
      $0.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
    }

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewPressed))
    self.addGestureRecognizer(tapGesture)
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    self.layer.cornerRadius = self.bounds.height / 2
  }

  // MARK: - Events

  @objc internal func viewPressed() {
    self.callback?(.tapped)
  }
}
