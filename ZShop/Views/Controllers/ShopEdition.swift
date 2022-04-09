// swiftlint:disable line_length
import Kingfisher
import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ShopEdition: UIViewController {
  let viewModel: ShopEditionViewModelType = ShopEditionViewModel()
  private let disposeBag = DisposeBag()

  private let filePicker = FilePicker(modes: [.image])
  private var shopSaveViewModel: ShopSaveViewModel?
  private var inPlaceLoader: InPlaceLoader?

  internal enum Callback {
    case save(Shop)
    case back
  }
  internal var callback: ((Callback) -> Void)?
  
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var stackView: UIStackView!

  @IBOutlet weak var logoStackView: UIStackView!
  @IBOutlet weak var logoSection: TappableView!
  @IBOutlet weak var logoTitle: UILabel!
  @IBOutlet weak var logoCircle: UIView!
  @IBOutlet weak var logo: UIImageView!
  @IBOutlet weak var logoPlaceholder: UIImageView!

  @IBOutlet weak var pencilContainer: UIView!
  @IBOutlet weak var pencil: UIImageView!

  @IBOutlet weak var nameStackView: UIStackView!
  @IBOutlet weak var nameSection: TappableView!
  @IBOutlet weak var nameTitle: UILabel!
  @IBOutlet weak var name: UILabel!

  @IBOutlet weak var domainStackView: UIStackView!
  @IBOutlet weak var domainSection: TappableView!
  @IBOutlet weak var domainTitle: UILabel!
  @IBOutlet weak var domain: UILabel!

  @IBOutlet weak var paypalStackView: UIStackView!
  @IBOutlet weak var paypalSection: TappableView!
  @IBOutlet weak var paypalTitle: UILabel!
  @IBOutlet weak var paypal: UILabel!

  let saveButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let saveTitle = NSLocalizedString(
      "shop_edition.save_button.title",
      value: "Save",
      comment: "Title of the button to save the changes in the shop edition page")
    $0.setTitle(saveTitle, for: .normal)
    $0.sizeToFit()
    _ = $0 |> greenFloatButtonStyle
  }

  // MARK: - Init

  internal static func configuredWith(editShop: EditShop) -> ShopEdition {
    let vc = Storyboard.ShopEdition.instantiate(ShopEdition.self)
    vc.configureWith(editShop: editShop)
    vc.filePicker.hostViewController = vc
    vc.filePicker.allowsMultipleSelection = false
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

  internal func configureWith(editShop: EditShop) {
    viewModel.inputs.configureWith(editShop: editShop)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationController?.navigationBar.prefersLargeTitles = false
    title = NSLocalizedString(
      "shop_edition.title",
      value: "Edit your shop",
      comment: "Title of the view where the user can edit the properties of his shop")

    stackView.do {
      $0.axis = .vertical
      $0.distribution = .fill
      $0.isLayoutMarginsRelativeArrangement = true
    }

    let stackViews: [UIStackView] = [logoStackView, nameStackView, domainStackView, paypalStackView]
    stackViews.forEach {
      $0.isLayoutMarginsRelativeArrangement = true
    }

    let editableViews: [TappableView] = [logoSection, nameSection, domainSection, paypalSection]
    editableViews.forEach {
      $0.backgroundColor(.white, for: .normal)
      $0.backgroundColor(UIColor.white.withBrightnessDelta(-0.04), for: .highlighted)
    }

    let titleLabels: [UILabel] = [logoTitle, nameTitle, domainTitle, paypalTitle]
    titleLabels.forEach {
      $0.font = .systemFont(ofSize: 18, weight: .bold)
      $0.backgroundColor = .clear
      $0.textColor = .zs_black
    }

    let labels: [UILabel] = [name, domain, paypal]
    labels.forEach {
      $0.font = .systemFont(ofSize: 18, weight: .regular)
      $0.backgroundColor = .clear
      $0.textColor = .zs_black
    }

    scrollView.do {
      $0.alwaysBounceVertical = true
      $0.contentInset = .init(top: 0, left: 0, bottom: 80, right: 0)
      $0.showsHorizontalScrollIndicator = false
    }

    logoSection.do {
      $0.backgroundColor(.hex(0xF5F5F5), for: .normal)
      $0.backgroundColor(UIColor.hex(0xF5F5F5).withBrightnessDelta(-0.04), for: .highlighted)
      $0.heightAnchor.constraint(equalToConstant: 220).isActive = true
      $0.addTarget(self, action: #selector(logoPressed), for: .touchUpInside)
    }

    logoTitle.do {
      $0.text = NSLocalizedString(
        "shop_edition.logo_section.title",
        value: "Logo",
        comment: "Title of the logo section")
    }

    logoPlaceholder.do {
      $0.contentMode = .center
      let size = CGSize(width: 36, height: 36)
      let shopImage = image(named: "shop", tintColor: .zs_light_gray)?.scaled(to: size)
      $0.image = shopImage
    }

    logo.do {
      $0.contentMode = .scaleAspectFit
      $0.backgroundColor = .white
      $0.alpha = 0.0
    }

    logoCircle.do {
      $0.isUserInteractionEnabled = false
      $0.clipsToBounds = true
      $0.layer.borderColor = UIColor.zs_light_gray.cgColor
      $0.layer.borderWidth = 1
      $0.layer.masksToBounds = true
    }

    pencilContainer.do {
      $0.isUserInteractionEnabled = false
      $0.clipsToBounds = true
      $0.layer.masksToBounds = true
      $0.layer.cornerRadius = 30 / 2
      $0.backgroundColor = .zs_light_gray
      let dist: CGFloat = 75.0 / cos(315.0 * .pi / 180.0) / 2
      $0.centerXAnchor.constraint(equalTo: logoCircle.centerXAnchor, constant: dist).isActive = true
      $0.centerYAnchor.constraint(equalTo: logoCircle.centerYAnchor, constant: dist).isActive = true
    }

    pencil.do {
      $0.contentMode = .center
      $0.backgroundColor = .clear
      let size = CGSize(width: 14, height: 14)
      let penImage = image(named: "edit-pencil", tintColor: .white)?.scaled(to: size)
      $0.image = penImage
    }

    nameSection.do {
      $0.addTarget(self, action: #selector(namePressed), for: .touchUpInside)
    }

    nameTitle.do {
      $0.text = NSLocalizedString(
        "shop_edition.name_section.title",
        value: "Name",
        comment: "Title of the name section")
    }

    domainSection.do {
      $0.addTarget(self, action: #selector(domainPressed), for: .touchUpInside)
    }

    domainTitle.do {
      $0.text = NSLocalizedString(
        "shop_edition.domain_section.title",
        value: "Domain name",
        comment: "Title of the domain section")
    }

    paypalSection.do {
      $0.addTarget(self, action: #selector(paypalPressed), for: .touchUpInside)
    }

    paypalTitle.do {
      $0.text = NSLocalizedString(
        "shop_edition.paypal_section.title",
        value: "PayPal account",
        comment: "Title of the paypal section")
    }

    saveButton.do {
      $0.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
      self.view.addSubview($0)
      $0.bottomAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
      $0.centerXAnchor
        .constraint(equalTo: view.centerXAnchor).isActive = true
    }

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()

    viewModel.inputs.viewDidLoad()
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: true)
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }

  override func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.name
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.adjustNameForText($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.domain
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.domain.text = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.paypal
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.adjustPaypalForShopEditionPaypal($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.logoUrl
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.logo?.alpha = 1.0
        if $0.isFileURL {
          let provider = LocalFileImageDataProvider(fileURL: $0)
          self?.logo?.kf.setImage(with: provider, options: [.transition(.fade(0.2))])
        } else {
          self?.logo?.setImageWithFast(fromUrl: $0)
        }
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentNameEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentShopEditionName(editShop: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentDomainEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentShopEditionDomain(editShop: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentPaypalEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentPaypalConnect(shop: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldSubmit
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        guard let `self` = self else { return }

        let inPlaceLoader = InPlaceLoader()
        inPlaceLoader.hostViewController = self
        self.inPlaceLoader = inPlaceLoader
        inPlaceLoader.start()

        self.shopSaveViewModel = ShopSaveViewModel()
        self.bindShopSaveViewModel()
        self.shopSaveViewModel?.inputs.configureWith(editShop: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.dismiss(withConfirm: $0)
      })
      .disposed(by: disposeBag)

    filePicker.viewModel.outputs.didPickMedias
      .map { $0.first }
      .unwrap()
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.viewModel.inputs.didPickPicture($0.url)
      })
      .disposed(by: disposeBag)
  }

  private func bindShopSaveViewModel() {
    shopSaveViewModel?.outputs.didSave
      .delay(0.8, scheduler: AppEnvironment.current.mainScheduler)
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.save($0))
      })
      .disposed(by: disposeBag)

    shopSaveViewModel?.outputs.shouldCompleteLoader
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.inPlaceLoader?.complete()
      })
      .disposed(by: disposeBag)
  }

  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    logoCircle.layer.cornerRadius = logoCircle.bounds.height / 2
  }

  // MARK: - Child VCs

  private func presentShopEditionName(editShop: EditShop) {
    let shopEditionName =
      ShopEditionName.configuredWith(name: editShop.conf?.companyInfo?.name ?? "")
    shopEditionName.callback = { [weak self] in
      switch $0 {
      case let .save(name):
        self?.viewModel.inputs.updateName(name)
        shopEditionName.dismiss(animated: true, completion: nil)
      }
    }
    self.present(shopEditionName, animated: true, completion: nil)
  }

  private func presentShopEditionDomain(editShop: EditShop) {
    let shopEditionDomain = ShopEditionDomain.configuredWith(domain: editShop.domain)
    shopEditionDomain.callback = { [weak self] in
      switch $0 {
      case let .save(domain):
        self?.viewModel.inputs.updateDomain(domain)
        shopEditionDomain.dismiss(animated: true, completion: nil)
      }
    }
    self.present(shopEditionDomain, animated: true, completion: nil)
  }

  private func presentPaypalConnect(shop: Shop) {
    let paypalConnect = PaypalConnect.configuredWith(shop: shop)
    paypalConnect.callback = { [weak self] in
      switch $0 {
      case .success:
        self?.viewModel.inputs.updatePaypal()
        paypalConnect.dismiss(animated: true, completion: nil)
      case .close:
        paypalConnect.dismiss(animated: true, completion: nil)
      }
    }
    self.present(paypalConnect, animated: true, completion: nil)
  }

  // MARK: - Events

  @objc internal func saveButtonPressed() {
    viewModel.inputs.submitButtonPressed()
  }

  @objc internal func logoPressed() {
    filePicker.viewModel.inputs.addFilesButtonPressed()
  }

  @objc internal func namePressed() {
    viewModel.inputs.namePressed()
  }

  @objc internal func domainPressed() {
    viewModel.inputs.domainPressed()
  }

  @objc internal func paypalPressed() {
    viewModel.inputs.paypalPressed()
  }

  // MARK: - Dismiss

  private func dismiss(withConfirm confirmation: Bool) {

    let dismissAction = { [weak self] in
      self?.callback?(.back)
    }

    if confirmation == false {
      dismissAction()
    } else {
      let message = NSLocalizedString(
        "shop_edition.exit_confirm.title",
        value: "Are you sure you want to quit? You will lose all your edits.",
        comment: "Title of alert to confirm if the user wants to quit the shop edition.")

      let loseEditsActionTitle = NSLocalizedString(
        "shop_edition.exit_confirm.lose_edits_title",
        value: "Lose Edits",
        comment: "Title of the button to confirm if the user wants to quit the shop edition. This will lose his edits")

      let cancelActionTitle = NSLocalizedString(
        "shop_edition.exit_confirm.cancel_title",
        value: "Cancel",
        comment: "Title of the button to confirm if the user wants to quit the shop edition. This will cancel the dismiss")

      let alert = UIAlertController.confirmationAlert(
        message: message,
        actionTitle: loseEditsActionTitle,
        cancelTitle: cancelActionTitle) { quit in
          if quit {
            dismissAction()
          }
      }
      self.navigationController?.present(alert, animated: true, completion: nil)
    }
  }

  // MARK: - State

  private func adjustNameForText(_ text: String) {
    if text.isEmpty {
      self.name.textColor = .zs_light_gray
      self.name.text = NSLocalizedString(
        "shop_edition.name.placeholder",
        value: "Set your shop's name",
        comment: "Placeholdet text displayed when no shop name is set yet.")
    } else {
      self.name.textColor = .zs_black
      self.name.text = text
    }
  }

  private func adjustPaypalForShopEditionPaypal(_ shopEditionPaypal: ShopEditionPaypal) {
    switch shopEditionPaypal {
    case .notConnected:
      self.paypal.textColor = .zs_light_gray
      self.paypal.text = NSLocalizedString(
        "shop_edition.paypal.placeholder",
        value: "Connect your Paypal account",
        comment: "Placeholdet text displayed when the paypal account is not connected.")
    case .connectedMissingInfo:
      self.paypal.textColor = .zs_black
      self.paypal.text = "???"
    case let .connected(email: email):
      self.paypal.textColor = .zs_black
      self.paypal.text = email
    }
  }
}

extension ShopEdition {
  @objc override func shouldPopOnBackButton() -> Bool {
    viewModel.inputs.didDismiss()
    return false
  }
}
