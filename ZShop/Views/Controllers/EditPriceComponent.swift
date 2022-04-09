import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class EditPriceComponent: UIViewController {
  private(set) var viewModel: EditPriceComponentViewModelType = EditPriceComponentViewModel()
  private let disposeBag = DisposeBag()
  
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var priceTextField: UITextField!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var currencyView: UIView!
  @IBOutlet weak var currencyLabel: UILabel!
  @IBOutlet weak var currencyArrows: UIImageView!
  @IBOutlet weak var currencyButton: UIButton!
  
  // MARK: - Init
  
  internal static func configuredWith(priceInfo: PriceInfo?) -> EditPriceComponent {
    let vc = Storyboard.EditPriceComponent.instantiate(EditPriceComponent.self)
    vc.configureWith(priceInfo: priceInfo)
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
  
  internal func configureWith(priceInfo: PriceInfo?) {
    self.viewModel.inputs.configureWith(priceInfo: priceInfo)
  }
  
  // MARK: - UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()

    priceTextField.do {
      $0.font = .systemFont(ofSize: 60, weight: .medium)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.borderStyle = .none
      $0.backgroundColor = .clear
      $0.autocorrectionType = .no
      $0.adjustsFontSizeToFitWidth = true
      $0.returnKeyType = .continue
      $0.keyboardType = .decimalPad
      $0.enablesReturnKeyAutomatically = true
      $0.addTarget(
        self,
        action: #selector(priceTextFieldChanged(_:)),
        for: [.editingDidEndOnExit, .editingChanged]
      )
    }

    priceLabel.do {
      $0.isUserInteractionEnabled = true
      $0.font = .systemFont(ofSize: 60, weight: .medium)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.backgroundColor = .clear
      $0.adjustsFontSizeToFitWidth = true
      $0.minimumScaleFactor = 0.7
    }

    currencyView.do {
      $0.backgroundColor = .clear
      $0.layer.cornerRadius = 8
      $0.layer.borderWidth = 1
      $0.layer.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.8, alpha: 1.0).cgColor
    }

    currencyLabel.do {
      $0.textColor = .zs_black
      $0.backgroundColor = .clear
      $0.font = .systemFont(ofSize: 20, weight: .medium)
    }

    currencyArrows.do {
      $0.image = image(
        named: "drop-down-arrows",
        tintColor: UIColor(hue: 0, saturation: 0, brightness: 0.8, alpha: 1.0)
      )
      $0.backgroundColor = .clear
      $0.contentMode = .center
    }

    currencyButton.do {
      $0.backgroundColor = .clear
      $0.setTitle("", for: .normal)
      $0.addTarget(self, action: #selector(currencyButtonPressed), for: .touchUpInside)
      $0.setBackgroundColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
    }

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(titleLabelTapped))
    self.priceLabel.addGestureRecognizer(tapGesture)
    
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
    priceTextField.subviews
      .compactMap { $0 as? UILabel }
      .forEach {
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.5
    }
  }
  
  override func bindViewModel() {
    super.bindViewModel()
    
    priceTextField.rx.controlEvent(.editingDidEndOnExit)
      .bind { [weak self] in
        self?.viewModel.inputs.priceTextFieldDoneEditing()
      }
      .disposed(by: disposeBag)
    
    Keyboard.change
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe (onNext: { [weak self] change in
        self?.animateContainerViewBottomConstraint(change)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.formattedPriceText
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] text in
        self?.priceLabel.text = text
      })
      .disposed(by: disposeBag)

    viewModel.outputs.priceText
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] text in
        self?.priceTextField.alpha = text.isEmpty ? 1.0 : 0.0
        self?.priceLabel.alpha = text.isEmpty ? 0.0 : 1.0
        self?.priceTextField.text = text
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldGoToCurrencySelection
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.goToCurrencySelection(currencyCode: $0)
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.showKeyboard
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak textField = self.priceTextField] show in
        _ = show
          ? textField?.becomeFirstResponder()
          : textField?.resignFirstResponder()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldUpdateCurrencyTo
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.currencyLabel.text = $0.symbol + " (\($0.code))"
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldUpdatePlaceholder
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.priceTextField.placeholder = $0
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Events
  
  @objc internal func priceTextFieldChanged(_ textField: UITextField) {
    viewModel.inputs.priceChanged(textField.text ?? "")
  }
  
  @objc internal func nextButtonPressed(_ sender: UIButton) {
    viewModel.inputs.submitButtonPressed()
  }

  @objc internal func titleLabelTapped() {
    viewModel.inputs.titleLabelTapped()
  }

  @objc internal func currencyButtonPressed() {
    viewModel.inputs.currencyButtonPressed()
  }

  // MARK: - Navigation

  private func goToCurrencySelection(currencyCode: String) {
    let currency = Currency.currencyFrom(code: currencyCode, locale: AppEnvironment.current.locale)
    let currencySelection = CurrencySelection.configuredWith(currency: currency)
    currencySelection.modalPresentationStyle = .overFullScreen
    currencySelection.callback = { [weak self] in
      switch $0 {
      case let .save(currency: currency):
        self?.viewModel.inputs.didSetCurrencyTo(currency: currency)
        currencySelection.dismiss(animated: true, completion: nil)
      }
    }
    let navigationController = UINavigationController(rootViewController: currencySelection)
    self.present(navigationController, animated: true, completion: nil)
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
}
