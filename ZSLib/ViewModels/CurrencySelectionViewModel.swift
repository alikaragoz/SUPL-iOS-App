import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol CurrencySelectionViewModelInputs {
  // call to configure
  func configureWith(currency: Currency)

  // call when a currency is selected
  func didSelectRow(_ row: Int)

  // call when the cancel button is pressed
  func cancelButtonPressed()

  // call when the view will appear
  func viewWillAppear()

  // call when the view did appear
  func viewDidAppear()
}

public protocol CurrencySelectionViewModelOutputs {
  // emits when the currencies should be loaded
  var shouldLoadCurrencies: Observable<[Currency]> { get }

  // emits when the view should be dismissed
  var shouldDismiss: Observable<Void> { get }

  // emits when we should save
  var shouldSave: Observable<Currency> { get }

  // emits when the table view should highlight a specific index
  var shouldFocusOnIndex: Observable<Int> { get }
}

public protocol CurrencySelectionViewModelType {
  var inputs: CurrencySelectionViewModelInputs { get }
  var outputs: CurrencySelectionViewModelOutputs { get }
}

public class CurrencySelectionViewModel: CurrencySelectionViewModelType,
  CurrencySelectionViewModelInputs,
CurrencySelectionViewModelOutputs {

  public var inputs: CurrencySelectionViewModelInputs { return self }
  public var outputs: CurrencySelectionViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {

    let currencies = Currency
      .currenciesFrom(codes: Paypal.currencies, locale: AppEnvironment.current.locale)
      .sorted { $0.name < $1.name }

    shouldLoadCurrencies = viewWillAppearProperty
      .map { currencies }

    shouldFocusOnIndex = shouldLoadCurrencies
      .withLatestFrom(configureProperty.unwrap())
      .map { currencies.firstIndex(of: $0) }
      .unwrap()

    shouldDismiss = cancelButtonPressedProperty
    shouldSave = didSelectRowProperty.unwrap().map { currencies[$0] }.unwrap()

    viewWillAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedCurrencySelection() }
      .disposed(by: disposeBag)

    shouldSave.subscribe(onNext: {
      AppEnvironment.current.analytics.trackChangedCurrency(code: $0.code)
    }).disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let configureProperty = BehaviorRelay<Currency?>(value: nil)
  public func configureWith(currency: Currency) {
    self.configureProperty.accept(currency)
  }

  private let viewWillAppearProperty = PublishSubject<Void>()
  public func viewWillAppear() {
    self.viewWillAppearProperty.onNext(())
  }

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  private let saveButtonPressedProperty = PublishSubject<Void>()
  public func saveButtonPressed() {
    self.saveButtonPressedProperty.onNext(())
  }

  private let cancelButtonPressedProperty = PublishSubject<Void>()
  public func cancelButtonPressed() {
    self.cancelButtonPressedProperty.onNext(())
  }

  private let didSelectRowProperty = BehaviorRelay<Int?>(value: nil)
  public func didSelectRow(_ row: Int) {
    self.didSelectRowProperty.accept(row)
  }

  // MARK: - Outputs

  public var shouldLoadCurrencies: Observable<[Currency]>
  public var shouldDismiss: Observable<Void>
  public var shouldSave: Observable<Currency>
  public var shouldFocusOnIndex: Observable<Int>
}
