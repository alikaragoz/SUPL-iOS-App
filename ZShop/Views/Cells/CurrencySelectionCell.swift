import UIKit
import Kingfisher
import RxSwift
import ZSAPI
import ZSLib
import ZSPrelude

public final class CurrencySelectionCell: UITableViewCell, ValueCell {
  private let viewModel: CurrencySelectionCellViewModelType = CurrencySelectionCellViewModel()
  private let disposeBag = DisposeBag()

  private let name = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .white
    $0.numberOfLines = 1
    $0.font = UIFont.systemFont(ofSize: 18.0, weight: .regular)
    $0.textColor = .zs_black
    $0.textAlignment = .left
  }

  private let code = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .white
    $0.numberOfLines = 1
    $0.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
    $0.textColor = UIColor.zs_black.withBrightnessDelta(0.3)
    $0.textAlignment = .right
  }

  override public var isSelected: Bool {
    didSet {
      self.name.textColor = isSelected ? .hex(0x0076FF) : .zs_black
      self.code.textColor = isSelected ? .hex(0x0076FF) : UIColor.zs_black.withBrightnessDelta(0.3)
    }
  }

  // MARK: Init

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    self.setupBindings()

    contentView.do {
      $0.backgroundColor = .white
    }

    name.do {
      contentView.addSubview($0)
      $0.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20.0).isActive = true
      $0.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0).isActive = true
      $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0).isActive = true
    }

    code.do {
      contentView.addSubview($0)
      $0.leftAnchor.constraint(equalTo: name.rightAnchor, constant: 10.0).isActive = true
      $0.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -10.0).isActive = true
      $0.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0).isActive = true
      $0.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0).isActive = true
    }

    let selectedBackgoundView = UIView()
    selectedBackgoundView.backgroundColor = UIColor.zs_light_gray.withBrightnessDelta(0.1)
    self.selectedBackgroundView = selectedBackgoundView
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  public func configureWith(value: Currency) {
    viewModel.inputs.configureWith(currency: value)
  }

  private func setupBindings() {

    viewModel.outputs.name
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.name.text = $0
        self?.layoutSubviews()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.code
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.code.text = $0
        self?.layoutSubviews()
      })
      .disposed(by: disposeBag)
  }
}
