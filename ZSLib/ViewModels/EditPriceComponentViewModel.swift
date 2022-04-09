import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol EditPriceComponentViewModelInputs {
  // call to configure with PriceInfo
  func configureWith(priceInfo: PriceInfo?)

  // call when submit button is pressed
  func submitButtonPressed()

  // call when the currency button is pressed
  func currencyButtonPressed()

  // string value of price textfield text
  func priceChanged(_ price: String)

  // call when the currency needs to be changes
  func didSetCurrencyTo(currency: Currency)

  // call when the tap the return key on the keyboard
  func priceTextFieldDoneEditing()

  // call when the view will appear
  func viewWillAppear()

  // call when the dismiss action has been made
  func didPressDismiss()

  // call when the view did dismiss
  func didDismiss()

  // call when the title label is tapped
  func titleLabelTapped()
}

public protocol EditPriceComponentViewModelOutputs {
  // emits formatted text that should be used in the textfield
  var formattedPriceText: Observable<String> { get }

  // bool value whether the price is valid
  var isValid: Observable<Bool> { get }

  // emits text that should be used to compute the formatted price
  var priceText: Observable<String> { get }

  // emits the currency symbol which shoul be put in the currency placeholder
  var shouldUpdatePlaceholder: Observable<String> { get }

  // Emits when the price has been submit
  var shouldSubmit: Observable<PriceInfo> { get }

  // emits whether the view should be dismissed with a confirmation prompt
  var shouldDismiss: Observable<Bool> { get }

  // emits when the currency selection should be shown
  var shouldGoToCurrencySelection: Observable<String> { get }

  // emits a boolean that determines if the keyboard should be shown or not
  var showKeyboard: Observable<Bool> { get }

  // emits when the currency should be changed
  var shouldUpdateCurrencyTo: Observable<Currency> { get }
}

public protocol EditPriceComponentViewModelType {
  var inputs: EditPriceComponentViewModelInputs { get }
  var outputs: EditPriceComponentViewModelOutputs { get }
}

public final class EditPriceComponentViewModel: EditPriceComponentViewModelType,
  EditPriceComponentViewModelInputs,
EditPriceComponentViewModelOutputs {

  public var inputs: EditPriceComponentViewModelInputs { return self }
  public var outputs: EditPriceComponentViewModelOutputs { return self }

  public init() {
    let previousPriceText = BehaviorRelay<String>(value: "")
    let currency = didSetCurrencyToProperty

    priceText = Observable
      .merge(
        didSetCurrencyToProperty.map { _ in () },
        priceChangedProperty.map { _ in () },
        priceInfoProperty.map { _ in () }
      )
      .withLatestFrom(
        Observable.merge(
          priceChangedProperty.asObservable(),
          // TODO: Switch to Double
          priceInfoProperty.unwrap().map { String(Double($0.amount) / 100) }
      ))
      .map {
        let text = $0.replacingOccurrences(of: ",", with: ".")
        let decimalSeparator = "."
        let separatorChar = Character(decimalSeparator)
        let zeroDot = "0" + "."

        if text == decimalSeparator {
          previousPriceText.accept(zeroDot)
          return zeroDot
        } else if text == "0" && previousPriceText.value == zeroDot {
          previousPriceText.accept("")
          return ""
        } else if text == "0" && previousPriceText.value == "" {
          previousPriceText.accept(zeroDot)
          return zeroDot
        } else if text.last == separatorChar && (text.filter { $0 == separatorChar }.count == 1) {
          previousPriceText.accept(text)
          return text
        } else if text.isEmpty {
          previousPriceText.accept("")
          return ""
        } else if isDecimal(text) {
          previousPriceText.accept(text)
          return text
        } else {
          return previousPriceText.value
        }
      }
      .startWith("")
      .share(replay: 1)

    isValid = priceText
      .map { isDecimal($0) ? $0 : "nok" }
      .map { Double($0) }
      .map { $0 ?? 0.0 }
      .map { ($0 > 0) }

    shouldSubmit = Observable
      .merge(submitButtonPressedProperty, priceTextFieldDoneEditingProperty)
      .withLatestFrom(priceText)
      .map(amountFrom)
      .unwrap()
      .map { PriceInfo(amount: $0, currency: currency.value.code) }

    showKeyboard = Observable.merge(
      titleLabelTappedProperty.map { _ in true },
      viewWillAppearProperty.map { _ in true },
      didDismissProperty.map { _ in false }
    )

    formattedPriceText = priceText

    shouldUpdatePlaceholder = Observable
      .merge(
        priceInfoProperty.map { _ in () },
        didSetCurrencyToProperty.map { _ in () }
      )
      .map { _ in currency.value.symbol }

    shouldUpdateCurrencyTo = didSetCurrencyToProperty.asObservable()
    shouldGoToCurrencySelection = currencyButtonPressedProperty.map { _ in currency.value.code }

    shouldDismiss = didPressDismissProperty
      .withLatestFrom(Observable.combineLatest(
        priceInfoProperty.unwrap().map { $0.amount },
        priceText.map(amountFrom)))
      .map { originalPrice, editedPrice in
        return originalPrice != editedPrice
    }
  }

  // MARK: - Inputs

  private let submitButtonPressedProperty = PublishSubject<Void>()
  public func submitButtonPressed() {
    self.submitButtonPressedProperty.onNext(())
  }

  private let currencyButtonPressedProperty = PublishSubject<Void>()
  public func currencyButtonPressed() {
    self.currencyButtonPressedProperty.onNext(())
  }

  private let priceChangedProperty = PublishSubject<String>()
  public func priceChanged(_ price: String) {
    self.priceChangedProperty.onNext(price)
  }

  private let didSetCurrencyToProperty =
    BehaviorRelay<Currency>(value: Currency.currencyFrom(locale: AppEnvironment.current.locale))
  public func didSetCurrencyTo(currency: Currency) {
    self.didSetCurrencyToProperty.accept(currency)
  }

  private let priceInfoProperty = BehaviorRelay<PriceInfo?>(value: nil)
  public func configureWith(priceInfo: PriceInfo?) {
    self.priceInfoProperty.accept(priceInfo)

    if let priceInfo = priceInfo {
      let currency = Currency.currencyFrom(code: priceInfo.currency, locale: AppEnvironment.current.locale)
      self.didSetCurrencyToProperty.accept(currency)
    } else {
      let osLocaleIndentifier = Locale.preferredLanguages.first ?? "en_US"
      let osLocale = Locale(identifier: osLocaleIndentifier)
      let osCurrency = Currency.currencyFrom(locale: osLocale)
      let currency = Paypal.currencies.contains(osCurrency.code)
        ? osCurrency
        : Currency.currencyFrom(code: "USD", locale: AppEnvironment.current.locale)
      self.didSetCurrencyToProperty.accept(currency)
    }
  }

  private let priceTextFieldDoneEditingProperty = PublishSubject<Void>()
  public func priceTextFieldDoneEditing() {
    self.priceTextFieldDoneEditingProperty.onNext(())
  }
  
  private let viewWillAppearProperty = PublishSubject<Void>()
  public func viewWillAppear() {
    self.viewWillAppearProperty.onNext(())
  }

  private let didDismissProperty = PublishSubject<Void>()
  public func didDismiss() {
    self.didDismissProperty.onNext(())
  }

  private let didPressDismissProperty = PublishSubject<Void>()
  public func didPressDismiss() {
    self.didPressDismissProperty.onNext(())
  }

  private let titleLabelTappedProperty = PublishSubject<Void>()
  public func titleLabelTapped() {
    self.titleLabelTappedProperty.onNext(())
  }

  // MARK: - Outputs

  public var formattedPriceText: Observable<String>
  public var isValid: Observable<Bool>
  public var priceText: Observable<String>
  public var shouldSubmit: Observable<PriceInfo>
  public var shouldDismiss: Observable<Bool>
  public var showKeyboard: Observable<Bool>
  public var shouldGoToCurrencySelection: Observable<String>
  public var shouldUpdateCurrencyTo: Observable<Currency>
  public var shouldUpdatePlaceholder: Observable<String>
}

func isDecimal(_ text: String) -> Bool {
  let nsstring = text as NSString
  let pattern = "^([1-9]\\d{0,5}(\\.|\\,)\\d{1,2}|0(\\.|\\,)\\d{1,2}|[0-9]\\d{0,5})$"
  guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
    return false
  }
  let match = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsstring.length))
  return !match.isEmpty
}

private func amountFrom(string: String) -> Int? {
  return Double(string).map { Int(($0 * 100.0).rounded()) }
}
