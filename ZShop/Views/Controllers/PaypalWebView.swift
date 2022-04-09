import RxCocoa
import RxSwift
import WebKit
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class PaypalWebView: UIViewController {
  private let viewModel: PaypalWebViewModelType = PaypalWebViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case submit(PaypalCredentials)
    case dismiss
  }
  internal var callback: ((Callback) -> Void)?

  @IBOutlet weak var webView: WKWebView!
  @IBOutlet weak var overlay: UIView!
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var loadingLabel: UILabel!

  private var doneButton = UIBarButtonItem().then {
    $0.style = .done
    $0.title = NSLocalizedString(
      "paypal_webview.done_button.title",
      value: "Done",
      comment: "Title of the button which dismiss the webview.")
  }

  // MARK: - Init

  internal static func instance() -> PaypalWebView {
    let vc = Storyboard.PaypalWebView.instantiate(PaypalWebView.self)
    vc.configureWith(url: URL(string: "https://supl.co/api/v1/auth/create_paypal_app"))
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

  internal func configureWith(url: URL?) {
    viewModel.inputs.configureWith(url: url)
  }

  // MARK: - UIViewController
  override func viewDidLoad() {
    super.viewDidLoad()

    webView.navigationDelegate = self
    PaypalWebViewModel.JSFunction.allCases.forEach { [weak self] in
      guard let `self` = self else { return }
      self.webView.configuration.userContentController.add(self, name: $0.rawValue)
    }

    doneButton.do {
      $0.target = self
      $0.action = #selector(doneButtonPressed)
      self.navigationItem.leftItemsSupplementBackButton = true
      self.navigationItem.leftBarButtonItem = $0
    }

    loadingLabel.do {
      $0.backgroundColor = .clear
      $0.font = .systemFont(ofSize: 20, weight: .regular)
      $0.textColor = .zs_black
      $0.textAlignment = .center
      $0.lineBreakMode = .byWordWrapping
      $0.numberOfLines = 0
      $0.text = NSLocalizedString(
        "paypal_webview.loading_title",
        value: "👩🏼‍🚀 Hold on we are plugging to your PayPal account...",
        comment: "Title of the button which opens paypal connect view.")
    }

    progressView.progress = 0

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.shouldLoadUrl
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        let urlRequest = URLRequest(url: $0)
        self?.webView.load(urlRequest)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldEvaluateJS
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.webView.evaluateJavaScript($0, completionHandler: nil)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.didFinish
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.submit($0))
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldDismiss
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.dismiss)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldShowOverlay
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.adjustOverlayState($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.progress
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] progress in
        self?.progressView.setProgress(progress, animated: true)
      })
      .disposed(by: disposeBag)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    viewModel.inputs.viewDidAppear()
  }

  // MARK: - State

  private func adjustOverlayState(_ visible: Bool) {
    let alpha: CGFloat = visible ? 1 : 0
    UIView.animate(withDuration: 0.2, animations: {
      self.overlay.alpha = alpha
    })
  }

  // MARK: - Events

  @objc internal func doneButtonPressed(_ sender: UIButton) {
    viewModel.inputs.doneButtonPressed()
  }

  // MARK: - Cleaning

  internal func cleanWebViewHandlers() {
    webView.stopLoading()
    webView.navigationDelegate = nil
    PaypalWebViewModel.JSFunction.allCases.forEach { [weak self] in
      guard let `self` = self else { return }
      self.webView.configuration.userContentController.removeScriptMessageHandler(forName: $0.rawValue)
    }
  }
}

// MARK: - WKNavigationDelegate

extension PaypalWebView: WKNavigationDelegate {

  public func webView(_ webView: WKWebView,
                      decidePolicyFor navigationAction: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    viewModel.inputs.decidePolicyFor(navigationAction: navigationAction, decisionHandler: decisionHandler)
  }

  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    viewModel.inputs.didFinishLoadingCurrentUrl()
  }
}

// MARK: - WKScriptMessageHandler

extension PaypalWebView: WKScriptMessageHandler {
  func userContentController(_ userContentController: WKUserContentController,
                             didReceive message: WKScriptMessage) {
    viewModel.inputs.didReceiveMessage(message)
  }
}
