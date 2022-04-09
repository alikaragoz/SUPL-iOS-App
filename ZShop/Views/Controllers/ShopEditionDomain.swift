import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ShopEditionDomain: UIViewController {
  private let viewModel: ShopEditionDomainViewModelType = ShopEditionDomainViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case save(String)
  }
  internal var callback: ((Callback) -> Void)?

  @IBOutlet weak var container: UIView!
  @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!

  @IBOutlet weak var domainContainer: UIView!
  @IBOutlet weak var domainTextField: BackwardDetectableTextField!
  @IBOutlet weak var domainBaseLabel: UILabel!
  @IBOutlet weak var loader: UIActivityIndicatorView!

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
      "shop_edition.domain.title",
      value: "Set a domain name for your Shop",
      comment: "Title of the page where we ask the user to edit the domain name.")
  }

  let saveButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let saveTitle = NSLocalizedString(
      "shop_edition.domain.save_button.title",
      value: "Save",
      comment: "Title of the button to save the edited domain name in the edit domaine page")
    $0.setTitle(saveTitle, for: .normal)
    $0.sizeToFit()
    _ = $0 |> greenFloatButtonStyle
  }

  // MARK: - Init

  internal static func configuredWith(domain: String) -> ShopEditionDomain {
    let vc = Storyboard.ShopEditionDomain.instantiate(ShopEditionDomain.self)
    vc.configureWith(domain: domain)
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

  internal func configureWith(domain: String) {
    viewModel.inputs.configureWith(domain: domain)
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

    saveButton.do {
      $0.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
      container.addSubview($0)
      $0.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20).isActive = true
      $0.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
    }

    domainContainer.do {
      $0.isUserInteractionEnabled = false
    }

    domainTextField.do {
      $0.font = .systemFont(ofSize: 30, weight: .medium)
      $0.textColor = .zs_black
      $0.textAlignment = .right
      $0.borderStyle = .none
      $0.backgroundColor = .clear
      $0.autocorrectionType = .no
      $0.keyboardType = .alphabet
      $0.adjustsFontSizeToFitWidth = true
      $0.minimumFontSize = 30
      $0.callback = { [weak self] clbk in
        guard let `self` = self else { return }
        switch clbk {
        case .deleteBackward:
          let text = self.domainTextField.text ?? ""
          self.viewModel.inputs.deleteBackward(text: text)
        }
      }
      $0.addTarget(
        self,
        action: #selector(domainTextFieldChanged(_:)),
        for: [.editingDidEndOnExit, .editingChanged]
      )
    }

    domainBaseLabel.do {
      $0.font = .systemFont(ofSize: 30, weight: .medium)
      $0.textColor = .zs_light_gray
      $0.textAlignment = .left
      $0.backgroundColor = .clear
      $0.numberOfLines = 1
      $0.adjustsFontSizeToFitWidth = false
    }

    loader.do {
      $0.hidesWhenStopped = true
    }

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func bindViewModel() {
    super.bindViewModel()

    Keyboard.change
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe (onNext: { [weak self] change in
        self?.animateContainerViewBottomConstraint(change)
      })
      .disposed(by: disposeBag)

    self.viewModel.outputs.shouldSubmit
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.save($0))
        self?.viewModel.inputs.didDismiss()
      })
      .disposed(by: disposeBag)

    self.viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.dismiss(withConfirm: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.domainText
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.domainTextField.text = $0
        self?.domainContainer.layoutIfNeeded()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.domainBase
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.domainBaseLabel.text = "." + $0
        self?.domainContainer.layoutIfNeeded()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.isLoading
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] isLoading in
        self?.adjustToLoadingState(isLoading: isLoading)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.isDomainValid
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.domainTextField.textColor = $0 ? .zs_green : UIColor.hex(0xEA1B1B)
        self?.saveButton.isEnabled = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.isEditing
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.domainTextField.textColor = .zs_black
      })
      .disposed(by: disposeBag)

    viewModel.outputs.showKeyboard
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak textField = self.domainTextField] show in
        _ = show
          ? textField?.becomeFirstResponder()
          : textField?.resignFirstResponder()
      })
      .disposed(by: disposeBag)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.inputs.viewWillAppear()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }

  // MARK: - Events

  @objc internal func domainTextFieldChanged(_ textField: UITextField) {
    viewModel.inputs.domainChanged(textField.text ?? "")
  }

  @objc internal func closeButtonPressed() {
    self.viewModel.inputs.didPressDismiss()
  }

  @objc internal func saveButtonPressed() {
    self.viewModel.inputs.submitButtonPressed()
  }

  // MARK: - Keyboard

  private func animateContainerViewBottomConstraint(_ change: Keyboard.Change) {
    if change.notificationName == UIResponder.keyboardWillShowNotification {
      self.containerViewBottomConstraint.constant = change.frame.height
    } else {
      self.containerViewBottomConstraint.constant = 0
    }

    UIView.animate(withDuration: change.duration, delay: 0, options: change.options, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }

  // MARK: - State

  private func adjustToLoadingState(isLoading: Bool) {
    self.saveButton.isEnabled = !isLoading
    isLoading
      ? self.loader.startAnimating()
      : self.loader.stopAnimating()
  }
  
  // MARK: - Misc

  private func dismiss(withConfirm confirmation: Bool) {

    let dismissAction = { [weak self] in
      self?.viewModel.inputs.didDismiss()
      self?.dismiss(animated: true, completion: nil)
    }

    if confirmation == false {
      dismissAction()
    } else {
      let message = NSLocalizedString(
        "shop_edition.domain.exit_confirm.title",
        value: "Are you sure you want to quit? You will lose all your edits on the domain name.",
        comment: "Title of alert to confirm if the user wants to quit the domaine name edition.")

      let quitActionTitle = NSLocalizedString(
        "shop_edition.domain.exit_confirm.lose_edits_title",
        value: "Lose Edits",
        comment: "Title of the button to confirm the exit.")

      let cancelActionTitle = NSLocalizedString(
        "shop_edition.domain.exit_confirm.cancel_title",
        value: "Cancel",
        comment: "Title of the button to cancel the exit.")

      let alert = UIAlertController.confirmationAlert(
        message: message,
        actionTitle: quitActionTitle,
        cancelTitle: cancelActionTitle) { quit in
          if quit {
            dismissAction()
          }
      }

      self.present(alert, animated: true, completion: nil)
    }
  }
}
