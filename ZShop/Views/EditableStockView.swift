import UIKit
import RxCocoa
import RxSwift
import ZSAPI
import ZSLib

public final class EditableStockView: TappableView {
  private let viewModel: EditableStockViewModelType = EditableStockViewModel()
  private let disposeBag = DisposeBag()

  private let stockImageView = UIImageView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.image = image(named: "stock")
    $0.contentMode = .scaleAspectFit
    $0.backgroundColor = .clear
    $0.tintColor = .zs_black
  }

  private let unlimitedImageView = UIImageView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.contentMode = .scaleAspectFit
    let size = CGSize(width: 22, height: 22)
    $0.image = image(named: "infinite")?.scaled(to: size)
    $0.backgroundColor = .clear
    $0.tintColor = .zs_black
  }

  private let pencilImageView = UIImageView().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.image = image(named: "edit-pencil")
    $0.contentMode = .scaleAspectFit
    $0.backgroundColor = .clear
    $0.tintColor = .zs_light_gray
  }

  private let stockLabel = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.font = .systemFont(ofSize: 24.0, weight: .medium)
    $0.numberOfLines = 0
    $0.textColor = .zs_black
    $0.text = NSLocalizedString(
      "edit_product.stock.label",
      value: "Stock:",
      comment: "Label in the stock field to edit the stock amount."
    )
  }

  private let amountLabel = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
    $0.font = .systemFont(ofSize: 24.0, weight: .medium)
    $0.numberOfLines = 0
    $0.textColor = .zs_black
  }

  private let loader = UIActivityIndicatorView(style: .gray).then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.hidesWhenStopped = true
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
    stockImageView.do {
      view.addSubview($0)
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 24.0).isActive = true
      $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
    }

    stockLabel.do {
      view.addSubview($0)
      $0.leftAnchor.constraint(equalTo: stockImageView.rightAnchor, constant: 10.0).isActive = true
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    pencilImageView.do {
      view.addSubview($0)
      $0.bottomAnchor.constraint(equalTo: stockLabel.bottomAnchor, constant: -3).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 18).isActive = true
      $0.heightAnchor.constraint(equalTo: $0.heightAnchor).isActive = true
    }

    self.setupBindings()
  }

  public func configureWith(editStock: EditStock, productId: String, shopId: String) {
    viewModel.inputs.configureWith(editStock: editStock, productId: productId, shopId: shopId)
  }

  private func setupBindings() {
    viewModel.outputs.state
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.adjustUI(for: $0)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - UI
  private func adjustUI(for state: EditableStockViewModel.State) {
    switch state {
    case .loading:
      installLoadingView()
    case .unlimited:
      installUnlimitedView()
    case let .amount(amount) :
      installAmountView(amount: amount)
    }
  }

  private func installLoadingView() {
    unlimitedImageView.removeFromSuperview()
    amountLabel.removeFromSuperview()
    loader.do {
      view.addSubview($0)
      $0.startAnimating()
      $0.leftAnchor.constraint(equalTo: stockLabel.rightAnchor, constant: 5.0).isActive = true
      $0.rightAnchor.constraint(equalTo: pencilImageView.leftAnchor, constant: -5.0).isActive = true
      $0.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
  }

  private func installAmountView(amount: Int) {
    unlimitedImageView.removeFromSuperview()
    loader.removeFromSuperview()
    amountLabel.do {
      view.addSubview($0)
      $0.text = String(amount) + "\u{00A0}"
      $0.sizeToFit()
      $0.leftAnchor.constraint(equalTo: stockLabel.rightAnchor, constant: 5.0).isActive = true
      $0.rightAnchor.constraint(equalTo: pencilImageView.leftAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: stockLabel.bottomAnchor).isActive = true
      $0.heightAnchor.constraint(equalTo: stockLabel.heightAnchor).isActive = true
    }
  }

  private func installUnlimitedView() {
    amountLabel.removeFromSuperview()
    loader.removeFromSuperview()
    unlimitedImageView.do {
      view.addSubview($0)
      $0.leftAnchor.constraint(equalTo: stockLabel.rightAnchor, constant: 5.0).isActive = true
      $0.rightAnchor.constraint(equalTo: pencilImageView.leftAnchor, constant: -5.0).isActive = true
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
  }
}
