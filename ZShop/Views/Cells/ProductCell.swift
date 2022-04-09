import UIKit
import Kingfisher
import RxSwift
import ZSAPI
import ZSLib
import ZSPrelude

public protocol ProductCellDelegate: class {
  func productCellDidTapEditButton(product: Product)
  func productCellDidTapShareButton(product: Product)
  func productCellDidTapPreviewButton(product: Product)
}

public final class ProductCell: UICollectionViewCell, ValueCell {
  private let viewModel: ProductCellViewModelType = ProductCellViewModel()
  private let disposeBag = DisposeBag()

  struct Constants {
    static let ratio: CGFloat = 4.0 / 5.0
    static let cornerRadius: CGFloat = 10.0

    struct Shadow {
      static let opacity: Float = 0.2
      static let radius: CGFloat = 6.0
      static let offset: CGSize = .init(width: 0, height: 4)
    }
  }

  public weak var delegate: ProductCellDelegate?

  private let menu = ProductCellMenu().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
  }

  private let container = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .zs_empty_view_gray
  }

  private let innerContentView = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
  }

  private let imageView = UIImageView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.contentMode = .scaleAspectFill
    $0.backgroundColor = .clear
  }

  private let gradientView = GradientView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.startPoint = .init(x: 0, y: 0)
    $0.endPoint = .init(x: 0, y: 1)

    let gradient: [(color: UIColor?, location: Float)] = [
      (UIColor.black.withAlphaComponent(0.0), 0.0),
      (UIColor.black.withAlphaComponent(0.25), 1.0)
    ]
    $0.setGradient(gradient)
  }

  private let priceContainer = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .white
    $0.layer.masksToBounds = true
  }

  private let price = UITextView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.font = UIFont.systemFont(ofSize: 13.0, weight: .bold)
    $0.textAlignment = .center
    $0.backgroundColor = .clear
    $0.textColor = .zs_black
    $0.isEditable = false
    $0.isScrollEnabled = false
    $0.isSelectable = false
    $0.textContainerInset = .zero
  }

  private let name = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.numberOfLines = 2
    $0.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
    $0.textColor = .white
    $0.textAlignment = .center
  }

  // MARK: Init

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupBindings()

    self.do {
      $0.clipsToBounds = false
      $0.layer.masksToBounds = false
    }

    contentView.do {
      $0.backgroundColor = .clear
    }

    menu.do {
      self.insertSubview($0, at: 0)
      $0.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 30.0).isActive = true
      $0.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
      $0.callback = { [weak self] o in
        switch o {
        case .edit: self?.viewModel.inputs.productCellDidTapEditButton()
        case .share: self?.viewModel.inputs.productCellDidTapShareButton()
        case .preview: self?.viewModel.inputs.productCellDidTapPreviewButton()
        }
      }
    }

    container.do {
      contentView.addSubview($0)
      $0.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true

      $0.backgroundColor = .clear
      $0.layer.masksToBounds = false
      $0.layer.shadowColor = UIColor.black.cgColor
      $0.layer.shadowRadius = Constants.Shadow.radius
      $0.layer.shadowOffset = Constants.Shadow.offset
      $0.layer.shadowOpacity = Constants.Shadow.opacity
      $0.layer.shouldRasterize = true
      $0.layer.rasterizationScale = UIScreen.main.scale
    }

    innerContentView.do {
      container.addSubview($0)
      $0.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true

      $0.backgroundColor = .zs_empty_view_gray
      $0.layer.masksToBounds = true
      $0.layer.borderColor = UIColor.zs_light_gray.cgColor
      $0.layer.borderWidth = 1.0
      $0.layer.cornerRadius = Constants.cornerRadius
      $0.layer.shouldRasterize = true
      $0.layer.rasterizationScale = UIScreen.main.scale
    }

    imageView.do {
      innerContentView.addSubview($0)
      $0.topAnchor.constraint(equalTo: innerContentView.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: innerContentView.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: innerContentView.rightAnchor).isActive = true
    }

    gradientView.do {
      innerContentView.addSubview($0)
      $0.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: innerContentView.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: innerContentView.rightAnchor).isActive = true
      $0.heightAnchor.constraint(equalTo: innerContentView.heightAnchor, multiplier: 0.3).isActive = true
    }

    priceContainer.do {
      innerContentView.addSubview($0)
      $0.centerXAnchor.constraint(equalTo: innerContentView.centerXAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: innerContentView.bottomAnchor, constant: -10.0).isActive = true
    }

    price.do {
      innerContentView.addSubview($0)
      $0.leftAnchor.constraint(equalTo: priceContainer.leftAnchor, constant: 2.0).isActive = true
      $0.rightAnchor.constraint(equalTo: priceContainer.rightAnchor, constant: -2.0).isActive = true
      $0.topAnchor.constraint(equalTo: priceContainer.topAnchor, constant: 3.0).isActive = true
      $0.bottomAnchor.constraint(equalTo: priceContainer.bottomAnchor, constant: -2.0).isActive = true
    }

    name.do {
      innerContentView.addSubview($0)
      $0.leftAnchor.constraint(equalTo: innerContentView.leftAnchor, constant: 20.0).isActive = true
      $0.rightAnchor.constraint(equalTo: innerContentView.rightAnchor, constant: -20.0).isActive = true
      $0.bottomAnchor.constraint(equalTo: price.topAnchor, constant: -10.0).isActive = true
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  public func configureWith(value: Product) {
    viewModel.inputs.configureWith(product: value)
  }

  private func setupBindings() {
    viewModel.outputs.image
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.imageView.kf.setImage(with: $0, options: [.transition(.fade(0.2))])
      })
      .disposed(by: disposeBag)

    viewModel.outputs.name
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.name.text = $0
        self?.layoutSubviews()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.price
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.price.text = $0
        self?.layoutSubviews()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.disabled
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.container.alpha = $0 ? 0.5 : 1.0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.didTapEditButton
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.delegate?.productCellDidTapEditButton(product: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.didTapShareButton
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.delegate?.productCellDidTapShareButton(product: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.didTapPreviewButton
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.delegate?.productCellDidTapPreviewButton(product: $0)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Recycle

  public override func prepareForReuse() {
    super.prepareForReuse()
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    viewModel.inputs.setSize(self.contentView.bounds.size)
    priceContainer.layer.cornerRadius = priceContainer.bounds.height / 2
  }

  // MARK: - Touches

  override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let translatedPoint = menu.convert(point, from: self)
    if menu.bounds.contains(translatedPoint) && self.isHidden == false {
      return menu.hitTest(translatedPoint, with: event)
    }
    return super.hitTest(point, with: event)
  }

  // MARK: - Decoration

  public override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
    super.apply(layoutAttributes)
    guard let attributes = layoutAttributes as? PaginationCollectionViewLayoutAttributes else { return }
    self.setDecorationTo(percent: attributes.decorationPercent)
  }

  private func setDecorationTo(percent: CGFloat) {
    container.do {
      $0.layer.shadowOpacity = Float(lerp(
        min: 0.2,
        max: Double(Constants.Shadow.opacity),
        t: Double(percent)
      ))

      $0.layer.shadowRadius = CGFloat(lerp(
        min: 4.0,
        max: Double(Constants.Shadow.radius),
        t: Double(percent)
      ))
    }
  }
}
