import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductEditionDesc: UIViewController {
  private let viewModel: ProductEditionDescViewModelType = ProductEditionDescViewModel()
  private(set) var editDescComponent: EditDescComponent?
  private let disposeBag = DisposeBag()
  
  internal enum Callback {
    case save(String)
  }
  internal var callback: ((Callback) -> Void)?
  
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
  
  let saveButton = FloatButton().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    let saveTitle = NSLocalizedString(
      "edit_product.description.save_button.title",
      value: "Save",
      comment: "Title of the button to save the edited description in the edit description page")
    $0.setTitle(saveTitle, for: .normal)
    $0.sizeToFit()
    _ = $0 |> greenFloatButtonStyle
  }
  
  let container = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
  }
  
  // MARK: - Init
  
  internal static func configuredWith(description: String) -> ProductEditionDesc {
    let vc = ProductEditionDesc(nibName: nil, bundle: nil)
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
    editDescComponent = EditDescComponent.configuredWith(description: description)
  }
  
  // MARK: - UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .white
    
    container.do {
      view.addSubview($0)
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    closeButton.do {
      view.addSubview($0)
      $0.heightAnchor.constraint(equalToConstant: 30.0).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20.0).isActive = true
      $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20.0).isActive = true
      $0.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
    }
    
    if let editDescComponent = self.editDescComponent {
      addSubController(editDescComponent)
    }
    
    if let containerView = editDescComponent?.containerView {
      saveButton.do {
        $0.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        containerView.addSubview($0)
        $0.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20).isActive = true
        $0.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
      }
    }
    
    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }
  
  override func bindViewModel() {
    super.bindViewModel()
    
    editDescComponent?.viewModel.outputs.shouldSubmit
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.save($0))
        self?.editDescComponent?.viewModel.inputs.didDismiss()
      })
      .disposed(by: disposeBag)
    
    editDescComponent?.viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.dismiss(withConfirm: $0)
      })
      .disposed(by: disposeBag)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }
  
  // MARK: - Sub VCs
  
  func addSubController(_ controller: UIViewController) {
    controller.do {
      addChild($0)
      container.addSubview($0.view)
      $0.view.translatesAutoresizingMaskIntoConstraints = false
      $0.view.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
      $0.view.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
      $0.view.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
      $0.view.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
      $0.didMove(toParent: self)
    }
  }
  
  // MARK: - Events
  
  @objc internal func closeButtonPressed() {
    editDescComponent?.viewModel.inputs.didPressDismiss()
  }
  
  @objc internal func saveButtonPressed() {
    editDescComponent?.viewModel.inputs.submitButtonPressed()
  }
  
  // MARK: - Misc
  
  private func dismiss(withConfirm confirmation: Bool) {
    
    let dismissAction = { [weak self] in
      self?.editDescComponent?.viewModel.inputs.didDismiss()
      self?.dismiss(animated: true, completion: nil)
    }
    
    if confirmation == false {
      dismissAction()
    } else {
      let message = NSLocalizedString(
        "edit_product.description.exit_confirm.title",
        value: "Are you sure you want to quit? You will lose all your edits on the description.",
        comment: "Title of alert to confirm if the user wants to quit the product description edition.")
      
      let quitActionTitle = NSLocalizedString(
        "edit_product.description.exit_confirm.lose_edits_title",
        value: "Lose Edits",
        comment: "Title of the button to confirm the exit.")
      
      let cancelActionTitle = NSLocalizedString(
        "edit_product.description.exit_confirm.cancel_title",
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
