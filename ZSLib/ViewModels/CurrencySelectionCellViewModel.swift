import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol CurrencySelectionCellViewModelInputs {
  // call to configure
  func configureWith(currency: Currency)
}

public protocol CurrencySelectionCellViewModelOutputs {
  // emits text that should be put into the localized currency name label
  var name: Observable<String> { get }

  // emits text that should be put into the currency code label
  var code: Observable<String> { get }
}

public protocol CurrencySelectionCellViewModelType {
  var inputs: CurrencySelectionCellViewModelInputs { get }
  var outputs: CurrencySelectionCellViewModelOutputs { get }
}

public class CurrencySelectionCellViewModel: CurrencySelectionCellViewModelType,
  CurrencySelectionCellViewModelInputs,
CurrencySelectionCellViewModelOutputs {

  public var inputs: CurrencySelectionCellViewModelInputs { return self }
  public var outputs: CurrencySelectionCellViewModelOutputs { return self }

  public init() {
    let currency = configureProperty.unwrap().distinctUntilChanged()
    name = currency.map { $0.name.capitalized }
    code = currency.map { $0.symbol + " (\($0.code))" }
  }

  // MARK: - Inputs

  private let configureProperty = BehaviorRelay<Currency?>(value: nil)
  public func configureWith(currency: Currency) {
    self.configureProperty.accept(currency)
  }

  // MARK: - Outputs

  public var name: Observable<String>
  public var code: Observable<String>
}
