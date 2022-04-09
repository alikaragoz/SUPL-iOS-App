import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib

private final class InPlaceLoaderView: UIView {
  let progress = ProgressLine()

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
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.backgroundColor = UIColor.white.withAlphaComponent(0.7)
    }

    progress.do {
      self.addSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }

  }

  // MARK: - Actions

  public func start() {
    progress.startSlowProgress()
  }

  public func complete() {
    progress.percentage = 1
  }
}

final class InPlaceLoader: NSObject {
  let viewModel: InPlaceLoaderViewModelType = InPlaceLoaderViewModel()
  private let disposeBag = DisposeBag()

  weak var hostViewController: UIViewController?
  private var loaderView: InPlaceLoaderView?

  // MARK: - Init

  override init() {
    super.init()
    bindViewModel()
  }

  // MARK: - Bindings

  private func bindViewModel() {
    viewModel.outputs.shouldStart
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.showLoader()
        self?.bindCurrentLoaderView()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldAbort
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        UIView.animate(withDuration: 0.2, animations: {
          self?.loaderView?.alpha = 0
        }, completion: { _ in
          self?.loaderView?.removeFromSuperview()
        })
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldComplete
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.loaderView?.complete()
      })
      .disposed(by: disposeBag)
  }

  private func bindCurrentLoaderView() {
    loaderView?.progress.viewModel.outputs.shouldFinish
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] _ in
        UIView.animate(withDuration: 0.2, animations: {
          self?.loaderView?.alpha = 0
        }, completion: { _ in
          self?.loaderView?.removeFromSuperview()
          self?.viewModel.inputs.didFinish()
        })
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Views

  private func showLoader() {
    guard let hostView = hostViewController?.view else {
      trackRuntimeError("Host View Controller not set")
      return
    }

    self.loaderView?.removeFromSuperview()

    let loaderView = InPlaceLoaderView().then {
      $0.alpha = 0
      hostView.addSubview($0)
      $0.topAnchor.constraint(equalTo: hostView.topAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: hostView.leftAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: hostView.bottomAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: hostView.rightAnchor).isActive = true
      self.loaderView = $0
    }

    UIView.animate(withDuration: 0.4, animations: {
      loaderView.alpha = 1
    }, completion: { _ in
      loaderView.start()
    })
  }

  // MARK: - Events

  public func start() {
    viewModel.inputs.start()
  }

  public func abort() {
    viewModel.inputs.abort()
  }

  public func complete() {
    viewModel.inputs.complete()
  }
}
