import RxCocoa
import RxSwift
import UIKit
import ZSPrelude
import ZSAPI
import ZSLib

final public class HomeShopHeader: UIView {
  private let viewModel: HomeShopHeaderViewModelType = HomeShopHeaderViewModel()
  private let disposeBag = DisposeBag()

  public enum Callback {
    case viewTapped
    case settingsTapped
  }
  internal var callback: ((Callback) -> Void)?

  private let logo = UIView().then {
    $0.isUserInteractionEnabled = false
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .zs_black
    $0.clipsToBounds = true
    $0.layer.borderWidth = 1.0
    $0.layer.borderColor = UIColor.zs_black.withAlphaComponent(0.1).cgColor
    $0.layer.masksToBounds = true
  }

  private let shopIcon = UIImageView().then {
    $0.isUserInteractionEnabled = false
    $0.translatesAutoresizingMaskIntoConstraints = false
    let size = CGSize(width: 24, height: 24)
    let im = image(named: "shop", tintColor: .white)?.scaled(to: size)
    $0.contentMode = .center
    $0.image = im
  }

  private let logoPicture = UIImageView().then {
    $0.isUserInteractionEnabled = false
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.contentMode = .scaleAspectFit
    $0.backgroundColor = .white
    $0.alpha = 0.0
  }

  private let name = UILabel().then {
    $0.isUserInteractionEnabled = false
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.font = UIFont.systemFont(ofSize: 28.0, weight: .bold)
    $0.textAlignment = .left
    $0.backgroundColor = .clear
    $0.numberOfLines = 1
    $0.textColor = .zs_black
    $0.adjustsFontSizeToFitWidth = true
    $0.minimumScaleFactor = 0.7
  }

  private let url = UILabel().then {
    $0.isUserInteractionEnabled = false
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.font = UIFont.systemFont(ofSize: 15.0, weight: .regular)
    $0.textAlignment = .left
    $0.backgroundColor = .clear
    $0.numberOfLines = 1
    $0.textColor = UIColor(hue: 0, saturation: 0, brightness: 0.4, alpha: 1.0)
    $0.adjustsFontSizeToFitWidth = true
    $0.minimumScaleFactor = 0.7
  }

  private let gearButton = UIButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let size = CGSize(width: 28, height: 28)
    let gearNormal = image(named: "gear", tintColor: .zs_black)?.scaled(to: size)
    let gearHighlighted =
      image(named: "gear", tintColor: UIColor.zs_black.withBrightnessDelta(-0.05))?.scaled(to: size)
    $0.setImage(gearNormal, for: .normal)
    $0.setImage(gearHighlighted, for: .highlighted)
    $0.sizeToFit()
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
    self.setupBindings()

    self.do {
      $0.backgroundColor = .clear
    }

    logo.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
      $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
    }

    shopIcon.do {
      logo.addSubview($0)
      $0.centerXAnchor.constraint(equalTo: logo.centerXAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: logo.centerYAnchor).isActive = true
    }

    logoPicture.do {
      logo.addSubview($0)
      $0.topAnchor.constraint(equalTo: logo.topAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: logo.leftAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: logo.bottomAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: logo.rightAnchor).isActive = true
    }

    name.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: logo.rightAnchor, constant: 10).isActive = true
      $0.topAnchor.constraint(equalTo: logo.topAnchor).isActive = true
    }

    url.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: name.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: name.rightAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: name.bottomAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: logo.bottomAnchor).isActive = true
    }

    gearButton.do {
      self.addSubview($0)
      $0.addTarget(self, action: #selector(gearButtonPressed), for: .touchUpInside)
      $0.leftAnchor.constraint(equalTo: name.rightAnchor, constant: 5).isActive = true
      $0.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
      $0.heightAnchor.constraint(equalToConstant: 28).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewPressed))
    self.addGestureRecognizer(tapGesture)
  }

  private func setupBindings() {
    viewModel.outputs.name
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.name.text = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.url
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.url.text = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.logoUrl
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.logoPicture.alpha = 1.0
        self?.logoPicture.setImageWithFast(fromUrl: $0)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Configuration

  public func configureWith(shop: Shop) {
    viewModel.inputs.configureWith(shop: shop)
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    logo.layer.cornerRadius = logo.bounds.height / 2
  }

  // MARK: - Events

  @objc internal func viewPressed() {
    self.callback?(.viewTapped)
  }

  @objc internal func gearButtonPressed() {
    self.callback?(.settingsTapped)
  }
}
