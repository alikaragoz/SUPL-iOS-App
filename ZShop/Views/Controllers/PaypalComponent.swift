import RxCocoa
import RxSwift
import SafariServices
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class PaypalComponent: NSObject {
  let viewModel: PaypalComponentViewModelType = PaypalComponentViewModel()
  private let disposeBag = DisposeBag()
  
  weak var hostViewController: UIViewController?
  private var paypalWebView: PaypalWebView?

  // MARK: - Init
  
  override init() {
    super.init()
    bindViewModel()
  }
  
  // MARK: - Configuration
  
  internal func configureWith(shop: Shop) {
    viewModel.inputs.configureWith(shop: shop)
  }
  
  private func bindViewModel() {
    viewModel.outputs.shouldDismissPaypalWebView
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.paypalWebView?.cleanWebViewHandlers()
        self?.paypalWebView?.dismiss(animated: true, completion: nil)
        self?.paypalWebView = nil
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Auth
  
  public func startPaypalAuth() {
    let paypalWebView = PaypalWebView.instance()
    paypalWebView.callback = { [weak self] in
      switch $0 {
      case let .submit(paypalCredentials):
        self?.viewModel.inputs.paypalWebViewDidFinishWithPaypalCredentials(paypalCredentials)
      case .dismiss:
        self?.viewModel.inputs.paypalWebViewDidDismiss()
      }
    }
    self.paypalWebView = paypalWebView
    let navigationController = UINavigationController(rootViewController: paypalWebView)
    self.hostViewController?.present(navigationController, animated: true, completion: nil)
  }
}
