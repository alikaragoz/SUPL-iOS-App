// swiftlint:disable cyclomatic_complexity
import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductEditionStockViewModelInputs {
  // call to configure
  func configureWith(editStock: EditStock, productId: String, shopId: String)

  // call when submit button is pressed
  func submitButtonPressed()

  // string value of stock textfield text
  func stockChanged(_ stock: String)

  // call when the view will appear
  func viewWillAppear()

  // call when the view did appear
  func viewDidAppear()

  // call when the dismiss action has been made
  func didPressDismiss()

  // call when the view did dismiss
  func didDismiss()

  // call when the unlimited toogle is changed
  func setUnlimited(isUnlimited: Bool)

  // call when the delete key has been pressed
  func deleteBackward(text: String)
}

public protocol ProductEditionStockViewModelOutputs {
  // emits text that should be used in the text field
  var stockText: Observable<String> { get }

  // Emits when the stock has been submit
  var shouldSubmit: Observable<EditStock> { get }

  // emits whether the view should be dismissed with a confirmation prompt
  var shouldDismiss: Observable<Bool> { get }

  // emits whether the view should transition to the unlimited state
  var shouldShowUnlimited: Observable<Bool> { get }

  // emits a boolean that determines if the keyboard should be shown or not
  var showKeyboard: Observable<Bool> { get }

  // emits a boolean whether the we are in a loading state
  var isLoading: Observable<Bool> { get }
}

public protocol ProductEditionStockViewModelType {
  var inputs: ProductEditionStockViewModelInputs { get }
  var outputs: ProductEditionStockViewModelOutputs { get }
}

public class ProductEditionStockViewModel: ProductEditionStockViewModelType,
  ProductEditionStockViewModelInputs,
ProductEditionStockViewModelOutputs {

  public var inputs: ProductEditionStockViewModelInputs { return self }
  public var outputs: ProductEditionStockViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    let isLoading = BehaviorRelay<Bool>(value: true)
    let isUnlimited = BehaviorRelay<Bool>(value: true)
    let previousStockText = BehaviorRelay<String>(value: "")

    let initialStock = viewWillAppearProperty
      .withLatestFrom(configureWithProperty)
      .unwrap()
      .flatMap { args -> Observable<EditStock> in
        if args.editStock.type == .unmanaged { return .just(args.editStock) }
        if args.editStock.amount != nil { return .just(args.editStock) }
        return Product.getFromCacheOrFetchStock(productId: args.productId, shopId: args.shopId).map {
          let editStock = args.editStock
          editStock.amount = $0
          return editStock
        }
      }
      .do(onNext: { _ in isLoading.accept(false) })
      .catchErrorAndContinue { _ in
        isLoading.accept(false)
      }
      .share(replay: 1)

    let initialStockText = initialStock
      .map { stock -> String in
        let amount = stock.amount ?? 0
        if amount == 0 { return "" }
        return String(amount)
    }

    let initialUnlimitedToggle = viewWillAppearProperty
      .withLatestFrom(configureWithProperty)
      .unwrap()
      .map {
        return $0.editStock.type == .unmanaged
    }

    let stockAfterUnlimitedToggle = setUnlimitedProperty.map { _ in previousStockText.value }

    let formatedStockText = stockChangedProperty
      .map { text -> String in
        if isUnlimited.value && text.count > previousStockText.value.count {
          let lastChar = String(text.last ?? Character(""))
          previousStockText.accept(lastChar)
          return lastChar
        } else if isUnlimited.value && text.count < previousStockText.value.count {
          previousStockText.accept("")
          return ""
        } else if text.isEmpty {
          previousStockText.accept("")
          return ""
        } else if previousStockText.value.hasPrefix("0") {
          let lastChar = String(text.last ?? Character(""))
          previousStockText.accept(lastChar)
          return lastChar
        } else if text.hasPrefix("0") {
          previousStockText.accept("0")
          return "0"
        } else if isNumber(text) {
          previousStockText.accept(text)
          return text
        }
        return previousStockText.value
      }
      .share(replay: 1)

    let stockText = Observable
      .merge(initialStockText, formatedStockText, stockAfterUnlimitedToggle)
      .startWith("")

    let toggleUnlimitedWhenDeleteBackward = Observable
      .combineLatest(deleteBackwardProperty, previousStockText)
      .map { _ -> Bool? in
        guard isUnlimited.value == true else { return nil }
        return false
      }.unwrap()

    let turnOffUnlimitedWhenChangingStockText = formatedStockText
      .map { text -> Bool? in
        if !text.isEmpty { return false }
        return nil
      }.unwrap()

    self.stockText = stockText

    shouldDismiss = didPressDismissProperty
      .withLatestFrom(
        Observable.merge(
          isLoading
            .map {
              if $0 { return false }
              return nil
            }
            .unwrap(),
          Observable.combineLatest(initialStock, stockText, isUnlimited)
            .map { args in
              let initialStock = args.0
              let newStock = editStockFrom(stockText: args.1, isUnlimited: args.2)
              return (initialStock.amount != newStock.amount || initialStock.type != newStock.type)
          }
        )
    )

    shouldSubmit = submitButtonPressedProperty
      .withLatestFrom(
        Observable.combineLatest(
          configureWithProperty.unwrap().asObservable(),
          stockText,
          isUnlimited)
      )
      .map { args in
        let editStock = editStockFrom(stockText: args.1, isUnlimited: args.2)
        editStock.needsUpdate = (args.0.editStock != editStock && editStock.type == .supl)
        return editStock
    }

    shouldShowUnlimited = Observable
      .merge(initialUnlimitedToggle,
             setUnlimitedProperty,
             toggleUnlimitedWhenDeleteBackward,
             turnOffUnlimitedWhenChangingStockText)
      .startWith(true)
      .do(onNext: { isUnlimited.accept($0) })
      .distinctUntilChanged()

    self.isLoading = isLoading
      .distinctUntilChanged()
      .asObservable()

    showKeyboard = Observable.merge(
      viewWillAppearProperty.map { _ in true },
      didDismissProperty.map { _ in false }
    )

    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedEditProductStock() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let submitButtonPressedProperty = PublishSubject<Void>()
  public func submitButtonPressed() {
    self.submitButtonPressedProperty.onNext(())
  }

  private let stockChangedProperty = PublishSubject<String>()
  public func stockChanged(_ stock: String) {
    self.stockChangedProperty.onNext(stock)
  }

  private let viewWillAppearProperty = PublishSubject<Void>()
  public func viewWillAppear() {
    self.viewWillAppearProperty.onNext(())
  }

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  private let didDismissProperty = PublishSubject<Void>()
  public func didDismiss() {
    self.didDismissProperty.onNext(())
  }

  private let didPressDismissProperty = PublishSubject<Void>()
  public func didPressDismiss() {
    self.didPressDismissProperty.onNext(())
  }

  private let setUnlimitedProperty = PublishSubject<Bool>()
  public func setUnlimited(isUnlimited: Bool) {
    self.setUnlimitedProperty.onNext(isUnlimited)
  }

  private let deleteBackwardProperty = PublishSubject<String>()
  public func deleteBackward(text: String) {
    self.deleteBackwardProperty.onNext(text)
  }

  private typealias ConfigureParams = (editStock: EditStock, productId: String, shopId: String)
  private let configureWithProperty = BehaviorRelay<ConfigureParams?>(value: nil)
  public func configureWith(editStock: EditStock, productId: String, shopId: String) {
    self.configureWithProperty.accept((editStock: editStock, productId: productId, shopId: shopId))
  }

  // MARK: - Outputs

  public var stockText: Observable<String>
  public var shouldSubmit: Observable<EditStock>
  public var shouldDismiss: Observable<Bool>
  public var showKeyboard: Observable<Bool>
  public var shouldShowUnlimited: Observable<Bool>
  public var isLoading: Observable<Bool>
}

private func isNumber(_ text: String) -> Bool {
  let nsstring = text as NSString
  let pattern = "[0-9]"
  guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
    return false
  }
  let match = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsstring.length))
  return !match.isEmpty
}

private func editStockFrom(stockText: String, isUnlimited: Bool) -> EditStock {
  let type: EditStock.`Type`
  let amount: Int?

  if isUnlimited {
    type = .unmanaged
    amount = nil
  } else {
    type = .supl
    amount = Int(stockText.isEmpty ? "0" : stockText)
  }

  return EditStock(type: type, amount: amount)
}
