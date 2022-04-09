import RxCocoa
import RxSwift
import SafariServices
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductCreationShare: UIViewController {
  private let viewModel: ProductCreationShareViewModelType = ProductCreationShareViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case next(Product)
  }
  internal var callback: ((Callback) -> Void)?

  @IBOutlet weak var browserContainer: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var miniBrowser: MiniBrowser!
  @IBOutlet weak var copyLinkButton: FloatButton!
  @IBOutlet weak var skipButton: UIButton!

  // MARK: - Init

  internal static func configuredWith(product: Product) -> ProductCreationShare {
    let vc = Storyboard.ProductCreationShare.instantiate(ProductCreationShare.self)
    vc.configureWith(product: product)
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

  internal func configureWith(product: Product) {
    viewModel.inputs.configureWith(product: product)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    titleLabel.do {
      $0.backgroundColor = .clear
      $0.font = .systemFont(ofSize: 20, weight: .regular)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.numberOfLines = 2
      $0.lineBreakMode = .byWordWrapping
      $0.text = NSLocalizedString(
        "product_creation.share.title",
        value: "🎉 Your store is online!",
        comment: "Title of the page where the user can share his product page.")
    }

    descriptionLabel.do {
      $0.backgroundColor = .clear
      $0.font = .systemFont(ofSize: 16, weight: .regular)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.numberOfLines = 0
      $0.lineBreakMode = .byWordWrapping
      $0.text = NSLocalizedString(
        "product_creation.share.copy_description.title",
        value: "Copy this link and put it in your Instagram bio",
        comment: "Description on the share page after the creation explaining what to do with the link.")
    }

    miniBrowser.do {
      $0.layer.shadowColor = UIColor.black.cgColor
      $0.layer.shadowRadius = 20
      $0.layer.shadowOffset = .init(width: 0, height: 5)
      $0.layer.shadowOpacity = 0.2
      $0.callback = { [weak self] in
        switch $0 {
        case .coverPressed:
          self?.viewModel.inputs.browserPressed()
        }
      }
    }

    copyLinkButton.do {
      let title = NSLocalizedString(
        "product_creation.share.copy_link_button.title",
        value: "Copy Link",
        comment: "Title of the button which copies the link of the shop")
      $0.setTitle(title, for: .normal)
      $0.sizeToFit()
      $0.addTarget(self, action: #selector(copyLinkButtonPressed), for: .touchUpInside)
      _ = $0 |> greenFloatButtonStyle
    }

    skipButton.do {
      let title = NSLocalizedString(
        "product_creation.share.skip_button.title",
        value: "skip",
        comment: "Title of the button to skip the sharing page at the end of the product creation.")
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

    browserContainer.clipsToBounds = false

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.shopDomain
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.miniBrowser.configureWith(url: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.presentSafariWebview
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToSafariBrowser(url: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldGoToNext
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.next($0))
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

  // MARK: -

  private func goToSafariBrowser(url: URL) {
    let controller = SFSafariViewController(url: url)
    controller.modalPresentationStyle = .overFullScreen
    self.present(controller, animated: true, completion: nil)
  }

  // MARK: - Events

  @objc internal func copyLinkButtonPressed(_ sender: UIButton) {
    viewModel.inputs.copyLinkButtonPressed()
  }

  @objc internal func skipButtonPressed(_ sender: UIButton) {
    viewModel.inputs.skipButtonPressed()
  }
}
