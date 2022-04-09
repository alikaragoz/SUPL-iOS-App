import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductCreationPicture: ProductCreationBase {
  private let viewModel: ProductCreationPictureViewModelType = ProductCreationPictureViewModel()
  private let disposeBag = DisposeBag()

  private let filePicker = FilePicker(modes: [.image, .video])

  @IBOutlet weak var backButton: FloatButton!
  @IBOutlet weak var uploadButton: FloatButton!

  // MARK: - Init

  internal static func instance() -> ProductCreationPicture {
    let vc = Storyboard.ProductCreationPicture.instantiate(ProductCreationPicture.self)
    vc.filePicker.hostViewController = vc
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
      "product_creation.picture.title",
      value: "📸 Upload your product videos and pictures",
      comment: "Title of the page where the user can upload his product video and pictures.")

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

    uploadButton.do {
      let title = NSLocalizedString(
        "product_creation.picture.upload_button.title",
        value: "Add some medias",
        comment: "Title of the button which opens the asset picker.")
      let size = CGSize(width: 22, height: 22)
      let addPictureNormal =
        image(named: "add-picture", tintColor: .white)?.scaled(to: size)
      let addPictureHighlighted =
        image(named: "add-picture", tintColor: UIColor.white.withBrightnessDelta(-0.05))?.scaled(to: size)
      $0.setImage(addPictureNormal, for: .normal)
      $0.setImage(addPictureHighlighted, for: .highlighted)
      $0.setTitle(title, for: .normal)
      $0.sizeToFit()
      $0.addTarget(self, action: #selector(addPictureButtonPressed), for: .touchUpInside)
      _ = $0 |> greenFloatButtonStyle <> centerTextAndImageFloatButtonStyle
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
      .subscribe(onNext: { [weak self] in
        self?.goToNextWith(medias: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldGoToPrevious
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.didGoBack()
      })
      .disposed(by: disposeBag)

    filePicker.viewModel.outputs.didPickMedias
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.viewModel.inputs.mediasPicked(medias: $0)
      })
      .disposed(by: disposeBag)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }

  // MARK: - Events

  @objc internal func backButtonPressed(_ sender: UIButton) {
    viewModel.inputs.backButtonPressed()
  }

  @objc internal func addPictureButtonPressed(_ sender: UIButton) {
    self.filePicker.viewModel.inputs.addFilesButtonPressed()
  }

  @objc override internal func closeButtonPressed() {
    self.delegate?.didDismiss(nil)
    viewModel.inputs.closeButtonPressed()
  }

  // MARK: - Flow

  private func goToNextWith(medias: [Media]) {
    delegate?.didSubmitWith(step: .picture(medias))
  }

  private func didGoBack() {
    delegate?.didGoBack()
  }
}
