import RxCocoa
import RxSwift
import UIKit
import ZSLib
import ZSPrelude

internal final class EditDescComponent: UIViewController {
  private(set) var viewModel: EditDescComponentViewModelType = EditDescComponentViewModel()
  private let disposeBag = DisposeBag()

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var descriptionTextField: UITextView!
  @IBOutlet weak var placeholderTextField: UITextView!
  @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!

  private let placeholderText = NSLocalizedString(
    "edit_product.description.textfield.placeholder",
    value: "Enter your description...",
    comment: "Placeholder when we ask the user for the description of the product he is creating."
  )

  // MARK: - Init

  internal static func configuredWith(description: String) -> EditDescComponent {
    let vc = Storyboard.EditDescComponent.instantiate(EditDescComponent.self)
    vc.configureWith(description: description)
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

  internal func configureWith(description: String) {
    viewModel.inputs.configureWith(description: description)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    let textFields = [descriptionTextField, placeholderTextField] as [UITextView]
    textFields.forEach {
      $0.font = .systemFont(ofSize: 24, weight: .medium)
      $0.textColor = .zs_black
      $0.backgroundColor = .clear
      $0.returnKeyType = .default
      $0.enablesReturnKeyAutomatically = true
      $0.contentInset = .init(top: 60, left: 0, bottom: 80, right: 0)
      $0.textContainerInset = .init(top: 0, left: 20, bottom: 0, right: 20)
    }

    placeholderTextField.do {
      $0.text = placeholderText
      $0.isEditable = false
      $0.textColor = .zs_light_gray
    }

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.inputs.viewWillAppear()
  }

  override func bindViewModel() {
    super.bindViewModel()

    descriptionTextField.rx.didChange
      .subscribe(onNext: { [weak self] _ in
        self?.viewModel.inputs.descriptionChanged(self?.descriptionTextField.text ?? "")
      })
      .disposed(by: disposeBag)

    Keyboard.change
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe (onNext: { [weak self] change in
        self?.animateContainerViewBottomConstraint(change)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.descriptionText
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] text in
        self?.descriptionTextField.text = text
      })
      .disposed(by: disposeBag)

    viewModel.outputs.showKeyboard
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak textField = self.descriptionTextField] show in
        _ = show
          ? textField?.becomeFirstResponder()
          : textField?.resignFirstResponder()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.isPlaceholderVisible
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.placeholderTextField.isHidden = !$0
      })
      .disposed(by: disposeBag)
  }
  
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
}
