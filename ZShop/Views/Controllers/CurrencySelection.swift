import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class CurrencySelection: UIViewController {
  private let viewModel: CurrencySelectionViewModelType = CurrencySelectionViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case save(currency: Currency)
  }
  internal var callback: ((Callback) -> Void)?

  let dataSource = CurrencySelectionDataSource()
  let tableView = UITableView()

  let cancelButton = UIBarButtonItem().then {
    $0.style = .done
    $0.title = NSLocalizedString(
      "currency_selection.cancel_button.title",
      value: "Cancel",
      comment: "Title of the button in the navigation bar which dismisses the view.")
  }

  // MARK: - Init

  internal static func configuredWith(currency: Currency) -> CurrencySelection {
    let vc = CurrencySelection(nibName: nil, bundle: nil)
    vc.configureWith(currency: currency)
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

  internal func configureWith(currency: Currency) {
    viewModel.inputs.configureWith(currency: currency)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    self.do {
      $0.navigationItem.largeTitleDisplayMode = .never
      $0.view.backgroundColor = .white
      $0.title = NSLocalizedString(
        "currency_selection.title",
        value: "Select your currency",
        comment: "Title of the view where we can set the currency."
      )
    }

    cancelButton.do {
      $0.target = self
      $0.action = #selector(cancelButtonPressed)
      self.navigationItem.leftBarButtonItem = $0
    }

    tableView.do {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.separatorColor = UIColor.zs_light_gray.withBrightnessDelta(0.1)
      $0.rowHeight = 60.0

      $0.dataSource = dataSource
      $0.delegate = self
      dataSource.registerClasses(tableView: $0)
      
      self.view.addSubview($0)
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.shouldLoadCurrencies
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.dataSource.load(currencies: $0)
        self?.tableView.reloadData()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.dismiss(animated: true, completion: nil)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldSave
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.save(currency: $0))
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldFocusOnIndex
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.tableView.selectRow(at: IndexPath(row: $0, section: 0), animated: true, scrollPosition: .middle)
      })
      .disposed(by: disposeBag)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.inputs.viewWillAppear()
    navigationController?.setNavigationBarHidden(false, animated: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }

  // MARK: - Events

  @objc internal func cancelButtonPressed() {
    self.viewModel.inputs.cancelButtonPressed()
  }
}

// MARK: - UITableViewDelegate

extension CurrencySelection: UITableViewDelegate {
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    viewModel.inputs.didSelectRow(indexPath.row)
  }
}
