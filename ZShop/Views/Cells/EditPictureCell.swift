import UIKit
import Kingfisher
import RxSwift
import ZSAPI
import ZSLib
import ZSPrelude

public final class EditPictureCell: UICollectionViewCell, ValueCell {
  private let viewModel = EditPictureCellViewModel()
  private let disposeBag = DisposeBag()
  
  struct Constants {
    static let aspectRatio: CGFloat = 4.0 / 5.0
    static let cornerRadius: CGFloat = 10.0
    
    struct Shadow {
      static let opacity: Float = 0.2
      static let radius: CGFloat = 6.0
      static let offset: CGSize = .init(width: 0, height: 4)
    }
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
  
  private let pencilImageView = UIImageView().then {
    let pencilImage = image(named: "edit-pencil")
    $0.image = pencilImage
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.contentMode = .scaleAspectFit
    $0.backgroundColor = .clear
    $0.tintColor = .white
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
      $0.heightAnchor.constraint(equalTo: innerContentView.heightAnchor, multiplier: 0.25).isActive = true
    }
    
    pencilImageView.do {
      gradientView.addSubview($0)
      $0.bottomAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: -10).isActive = true
      $0.rightAnchor.constraint(equalTo: gradientView.rightAnchor, constant: -10).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 22)
      $0.heightAnchor.constraint(equalTo: $0.widthAnchor)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  public func configureWith(value: EditPicture) {
    viewModel.inputs.configureWith(picture: value)
  }
  
  private func setupBindings() {
    viewModel.outputs.image
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        if $0.isFileURL {
          let provider = LocalFileImageDataProvider(fileURL: $0)
          self?.imageView.kf.setImage(with: provider, options: [.transition(.fade(0.2))])
        } else {
          self?.imageView.kf.setImage(with: $0, options: [.transition(.fade(0.2))])
        }
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Layout
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    viewModel.inputs.setSize(self.contentView.bounds.size)
  }
}
