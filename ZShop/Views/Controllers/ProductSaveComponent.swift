import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductSaveComponent: UIViewController {
  private(set) var viewModel: ProductSaveViewModelType = ProductSaveViewModel()
  private let disposeBag = DisposeBag()

  @IBOutlet weak var progress: LargeProgressCircle!

  // MARK: - Init

  internal static func configuredWith(shop: Shop, saveType: ProductSaveType) -> ProductSaveComponent {
    let vc = Storyboard.ProductSaveComponent.instantiate(ProductSaveComponent.self)
    vc.configureWith(shop: shop, saveType: saveType)
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

  internal func configureWith(shop: Shop, saveType: ProductSaveType) {
    viewModel.inputs.configureWith(shop: shop, saveType: saveType)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    progress.startSlowProgress()
  }

  override public func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.setProgression
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.progress.percentage = $0
      })
      .disposed(by: disposeBag)
  }
}
