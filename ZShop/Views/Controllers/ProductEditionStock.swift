import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductEditionStock: UIViewController {
  private let viewModel: ProductEditionStockViewModelType = ProductEditionStockViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case save(EditStock)
  }
  internal var callback: ((Callback) -> Void)?

  @IBOutlet weak var container: UIView!
  @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!

  @IBOutlet weak var controlsContainer: UIView!
  @IBOutlet weak var stockTextContainer: UIView!
  @IBOutlet weak var stockTextField: BackwardDetectableTextField!
  @IBOutlet weak var stockLabel: UILabel!

  @IBOutlet weak var loader: UIActivityIndicatorView!
  @IBOutlet weak var switchView: UIView!
  @IBOutlet weak var unlimitedLabel: UILabel!
  @IBOutlet weak var unlimitedSwitch: UISwitch!

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
      "edit_product.stock.title",
      value: "📦 Left in Stock",
      comment: "Title of the page where we ask the user to edit the stock.")
  }

  let saveButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let saveTitle = NSLocalizedString(
      "edit_product.stock.save_button.title",
      value: "Save",
      comment: "Title of the button to save the edited price in the edit price page")
    $0.setTitle(saveTitle, for: .normal)
    $0.sizeToFit()
    _ = $0 |> greenFloatButtonStyle
  }

  let unlimitedImage = UIImageView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.tintColor = .zs_black
    $0.image = image(named: "infinite")
  }

  // MARK: - Init

  internal static func configuredWith(editStock: EditStock,
                                      productId: String,
                                      shopId: String) -> ProductEditionStock {
    let vc = Storyboard.ProductEditionStock.instantiate(ProductEditionStock.self)
    vc.configureWith(editStock: editStock, productId: productId, shopId: shopId)
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

  internal func configureWith(editStock: EditStock, productId: String, shopId: String) {
    viewModel.inputs.configureWith(editStock: editStock, productId: productId, shopId: shopId)
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

    stockTextContainer.do {
      $0.isUserInteractionEnabled = false
    }

    controlsContainer.do {
      $0.isUserInteractionEnabled = true
      $0.clipsToBounds = false
    }

    stockTextField.do {
      $0.font = .systemFont(ofSize: 50, weight: .medium)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.placeholder = "0"
      $0.borderStyle = .none
      $0.backgroundColor = .clear
      $0.autocorrectionType = .no
      $0.keyboardType = .numberPad
      $0.adjustsFontSizeToFitWidth = true
      $0.minimumFontSize = 50
      $0.callback = { [weak self] clbk in
        guard let `self` = self else { return }
        switch clbk {
        case .deleteBackward:
          let text = self.stockTextField.text ?? ""
          self.viewModel.inputs.deleteBackward(text: text)
        }
      }
      $0.addTarget(
        self,
        action: #selector(stockTextFieldChanged(_:)),
        for: [.editingDidEndOnExit, .editingChanged]
      )
    }

    stockLabel.do {
      $0.font = .systemFont(ofSize: 50, weight: .medium)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.backgroundColor = .clear
      $0.adjustsFontSizeToFitWidth = false
    }

    loader.do {
      $0.hidesWhenStopped = true
    }

    unlimitedImage.do {
      view.addSubview($0)
      $0.centerXAnchor.constraint(equalTo: stockTextField.centerXAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: stockTextField.centerYAnchor).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 60).isActive = true
      $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
    }

    switchView.do {
      $0.backgroundColor = .zs_empty_view_gray
      $0.clipsToBounds = true
    }

    unlimitedSwitch.do {
      $0.addTarget(self, action: #selector(didToggleUnlimitedSwitch), for: .valueChanged)
    }

    unlimitedLabel.do {
      $0.font = .systemFont(ofSize: 18, weight: .medium)
      $0.textColor = UIColor.zs_black.withBrightnessDelta(0.4)
      $0.textAlignment = .center
      $0.numberOfLines = 1
      $0.backgroundColor = .zs_empty_view_gray
      $0.text = NSLocalizedString(
        "edit_product.stock.unlimited_switch_label",
        value: "Unlimited",
        comment: "Title next to the switch to toggle the unlimited state of the stock")
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

    viewModel.outputs.stockText
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] text in
        self?.stockTextField.alpha = text.isEmpty ? 1.0 : 0.0
        self?.stockLabel.alpha = text.isEmpty ? 0.0 : 1.0
        self?.stockTextField.text = text
        self?.stockLabel.text = text
      })
      .disposed(by: disposeBag)

    viewModel.outputs.isLoading
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.adjustToLoadingState(isLoading: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldShowUnlimited
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.adjustToUnlimitedState(isUnlimited: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.showKeyboard
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak textField = self.stockTextField] show in
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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    switchView.layer.cornerRadius = switchView.bounds.height / 2
  }

  // MARK: - Events

  @objc internal func stockTextFieldChanged(_ textField: UITextField) {
    viewModel.inputs.stockChanged(textField.text ?? "")
  }

  @objc internal func closeButtonPressed() {
    self.viewModel.inputs.didPressDismiss()
  }

  @objc internal func saveButtonPressed() {
    self.viewModel.inputs.submitButtonPressed()
  }

  @objc internal func didToggleUnlimitedSwitch(sender: UISwitch) {
    self.viewModel.inputs.setUnlimited(isUnlimited: sender.isOn)
  }

  // MARK: - State

  private func adjustToUnlimitedState(isUnlimited: Bool) {
    self.stockTextContainer.alpha = isUnlimited ? 0 : 1
    self.unlimitedImage.alpha = isUnlimited ? 1 : 0
    self.unlimitedSwitch.isOn = isUnlimited
  }

  private func adjustToLoadingState(isLoading: Bool) {
    UIView.animate(withDuration: 0.3) {
      self.controlsContainer.alpha = isLoading ? 0 : 1
      self.saveButton.isEnabled = !isLoading
    }
    isLoading
      ? self.loader.startAnimating()
      : self.loader.stopAnimating()
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
        "edit_product.stock.exit_confirm.title",
        value: "Are you sure you want to quit? You will lose all your edits on the stock.",
        comment: "Title of alert to confirm if the user wants to quit the product stock edition.")

      let quitActionTitle = NSLocalizedString(
        "edit_product.stock.exit_confirm.lose_edits_title",
        value: "Lose Edits",
        comment: "Title of the button to confirm the exit.")

      let cancelActionTitle = NSLocalizedString(
        "edit_product.stock.exit_confirm.cancel_title",
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
