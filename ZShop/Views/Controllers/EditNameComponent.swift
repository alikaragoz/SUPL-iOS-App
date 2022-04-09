import RxCocoa
import RxSwift
import UIKit
import ZSLib
import ZSPrelude

internal final class EditNameComponent: UIViewController {
  private(set) var viewModel: EditNameComponentViewModelType = EditNameComponentViewModel()
  private let disposeBag = DisposeBag()

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!
  
  // MARK: - Init
  
  internal static func configuredWith(name: String) -> EditNameComponent {
    let vc = Storyboard.EditNameComponent.instantiate(EditNameComponent.self)
    vc.configureWith(name: name)
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
  
  internal func configureWith(name: String) {
    self.viewModel.inputs.configureWith(name: name)
  }
  
  // MARK: - UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // name textfield
    nameTextField.do {
      $0.font = .systemFont(ofSize: 46, weight: .medium)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.borderStyle = .none
      $0.backgroundColor = .clear
      $0.autocorrectionType = .no
      $0.adjustsFontSizeToFitWidth = false
      $0.returnKeyType = .continue
      $0.autocapitalizationType = .words
      $0.enablesReturnKeyAutomatically = true
      $0.placeholder = NSLocalizedString(
        "edit_name.textfield.placeholder",
        value: "Name?",
        comment: "Placeholder when we ask the user for the name of the product he is creating.")

      $0.addTarget(
        self,
        action: #selector(nameTextFieldChanged(_:)),
        for: [.editingDidEndOnExit, .editingChanged]
      )
    }
    
    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.inputs.viewWillAppear()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // helps with placeholder autosizing to width
    nameTextField.subviews
      .compactMap { $0 as? UILabel }
      .forEach {
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.5
    }
  }
  
  override func bindViewModel() {
    super.bindViewModel()
    
    nameTextField.rx.controlEvent(.editingDidEndOnExit)
      .bind { [weak self] in
        self?.viewModel.inputs.nameTextFieldDoneEditing()
      }
      .disposed(by: disposeBag)
    
    Keyboard.change
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe (onNext: { [weak self] change in
        self?.animateContainerViewBottomConstraint(change)
        
      })
      .disposed(by: disposeBag)

    viewModel.outputs.nameText
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] text in
        self?.nameTextField.text = text
      })
      .disposed(by: disposeBag)

    viewModel.outputs.showKeyboard
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak textField = self.nameTextField] show in
        _ = show
          ? textField?.becomeFirstResponder()
          : textField?.resignFirstResponder()
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Events
  
  @objc internal func nameTextFieldChanged(_ textField: UITextField) {
    viewModel.inputs.nameChanged(textField.text ?? "")
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
