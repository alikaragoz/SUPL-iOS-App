import RxCocoa
import RxSwift
import UIKit
import WebKit
import ZSPrelude
import ZSLib

final public class MiniBrowser: UIView, NibLoading {
  private(set) var viewModel: MiniBrowserViewModelType = MiniBrowserViewModel()
  private let disposeBag = DisposeBag()

  internal enum Callback {
    case coverPressed
  }
  internal var callback: ((Callback) -> Void)?

  struct Constants {
    static let cornerRadius: CGFloat = 8
  }

  let lockImageView = UIImageView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.image = image(named: "lock")
    $0.tintColor = .zs_black
  }

  let urlLabel = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.font = .systemFont(ofSize: 13, weight: .regular)
    $0.textColor = .zs_black
    $0.textAlignment = .center
    $0.numberOfLines = 1
  }

  let navBar = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .hex(0xD8D8D8)
  }

  let urlFieldView = UIView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.layer.cornerRadius = Constants.cornerRadius
    $0.layer.masksToBounds = true
    $0.backgroundColor = .hex(0xF2F2F2)
  }

  let webView: WKWebView = {
    let contentController = WKUserContentController().then {
      let scriptSource: String = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=0.7, maximum-scale=0.7, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        head.appendChild(meta);
      """
      let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
      $0.addUserScript(script)
    }

    let config = WKWebViewConfiguration().then {
      $0.userContentController = contentController
      $0.ignoresViewportScaleLimits = true
    }

    let webView = WKWebView(frame: .zero, configuration: config).then {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.scrollView.isScrollEnabled = false
    }

    return webView
  }()

  let spinner = UIActivityIndicatorView(style: .gray).then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.hidesWhenStopped = true
  }

  let coverButton = UIButton(type: .custom).then {
    $0.setBackgroundColor(.clear, for: .normal)
    $0.setBackgroundColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
    $0.addTarget(self, action: #selector(coverButtonPressed), for: .touchUpInside)
  }

  // MARK: - Init

  public convenience init() {
    self.init(frame: .zero)
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }

  private func setup() {

    self.do {
      $0.backgroundColor = .clear
    }

    let contentView = UIView().then {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.layer.cornerRadius = Constants.cornerRadius
      $0.layer.borderWidth = 1.0
      $0.layer.borderColor = UIColor.black.withAlphaComponent(0.2).cgColor
      $0.layer.masksToBounds = true

      self.addSubview($0)
      $0.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    navBar.do {
      contentView.addSubview($0)
      $0.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
      $0.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    webView.do {
      $0.navigationDelegate = self

      let webViewBackground = UIView()
      webViewBackground.do {
        contentView.addSubview($0)
        $0.backgroundColor = .white
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
        $0.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        $0.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
      }

      contentView.addSubview($0)
      $0.topAnchor.constraint(equalTo: navBar.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    urlFieldView.do {
      navBar.addSubview($0)
      $0.leftAnchor.constraint(equalTo: navBar.leftAnchor, constant: 10).isActive = true
      $0.rightAnchor.constraint(equalTo: navBar.rightAnchor, constant: -10).isActive = true
      $0.centerYAnchor.constraint(equalTo: navBar.centerYAnchor).isActive = true
      $0.heightAnchor.constraint(equalToConstant: 25).isActive = true
    }

    urlLabel.do {
      urlFieldView.addSubview($0)
      $0.widthAnchor.constraint(lessThanOrEqualTo: urlFieldView.widthAnchor,
                                multiplier: 0.8).isActive = true
      $0.centerXAnchor.constraint(equalTo: urlFieldView.centerXAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: urlFieldView.centerYAnchor).isActive = true
    }

    lockImageView.do {
      urlFieldView.addSubview($0)
      $0.widthAnchor.constraint(equalToConstant: 10).isActive = true
      $0.heightAnchor.constraint(equalToConstant: 10).isActive = true
      $0.rightAnchor.constraint(equalTo: urlLabel.leftAnchor, constant: -5).isActive = true
      $0.centerYAnchor.constraint(equalTo: urlFieldView.centerYAnchor).isActive = true
    }

    spinner.do {
      contentView.addSubview($0)
      $0.centerXAnchor.constraint(equalTo: webView.centerXAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: webView.centerYAnchor).isActive = true
    }

    coverButton.do {
      $0.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview($0)
      $0.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
  }

  override public func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.urlText
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.urlLabel.text = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.loadWebViewWithUrl
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        let request = URLRequest(url: $0)
        self?.webView.load(request)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.loadWebViewWithUrl
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        let request = URLRequest(url: $0)
        self?.webView.load(request)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.setSpinnerState
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        $0
          ? self?.spinner.startAnimating()
          : self?.spinner.stopAnimating()

      })
      .disposed(by: disposeBag)

    viewModel.outputs.setWebViewState
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.webView.isHidden = !$0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldNotifyCoverPressed
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] _ in
        self?.callback?(.coverPressed)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Configure

  public func configureWith(url: URL) {
    viewModel.inputs.configureWith(url)
  }

  // MARK: - Events

  @objc internal func coverButtonPressed(_ sender: UIButton) {
    viewModel.inputs.coverButtonPressed()
  }
}

// MARK: - WKNavigationDelegate

extension MiniBrowser: WKNavigationDelegate {
  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    viewModel.inputs.webViewDidFinishLoading()
  }
}
