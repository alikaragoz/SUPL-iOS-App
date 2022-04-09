import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ShopEditionDomainViewModelInputs {
  // call to configure
  func configureWith(domain: String)

  // call when submit button is pressed
  func submitButtonPressed()

  // string value of domain textfield text
  func domainChanged(_ domain: String)

  // call when the view will appear
  func viewWillAppear()

  // call when the view did appear
  func viewDidAppear()

  // call when the dismiss action has been made
  func didPressDismiss()

  // call when the view did dismiss
  func didDismiss()

  // call when the delete key has been pressed
  func deleteBackward(text: String)
}

public protocol ShopEditionDomainViewModelOutputs {
  // emits text that should be used in the domain field
  var domainText: Observable<String> { get }

  // emits text that should be used in the domain base label
  var domainBase: Observable<String> { get }

  // Emits when the domain has been submit
  var shouldSubmit: Observable<String> { get }

  // emits whether the view should be dismissed with a confirmation prompt
  var shouldDismiss: Observable<Bool> { get }

  // emits a boolean that determines if the keyboard should be shown or not
  var showKeyboard: Observable<Bool> { get }

  // emits a boolean whether the we are in a loading state
  var isLoading: Observable<Bool> { get }

  // emits a boolean whether the domain is valid
  var isDomainValid: Observable<Bool> { get }

  // emits when the domain is editing
  var isEditing: Observable<Void> { get }
}

public protocol ShopEditionDomainViewModelType {
  var inputs: ShopEditionDomainViewModelInputs { get }
  var outputs: ShopEditionDomainViewModelOutputs { get }
}

public class ShopEditionDomainViewModel: ShopEditionDomainViewModelType,
  ShopEditionDomainViewModelInputs,
ShopEditionDomainViewModelOutputs {

  public var inputs: ShopEditionDomainViewModelInputs { return self }
  public var outputs: ShopEditionDomainViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    let isLoading = BehaviorRelay<Bool>(value: false)
    let previousDomainText = BehaviorRelay<String>(value: "")
    let checkDomain = PublishSubject<String>()
    let initialDomain = viewWillAppearProperty.withLatestFrom(configureWithProperty).take(1)
    let initialSubdomain = initialDomain.map {
      $0.replacingOccurrences(
        of: "." + AppEnvironment.current.apiService.serverConfig.providerDomain,
        with: ""
      )
    }
    let isDomainValid = PublishSubject<Bool>()
    let editedDomainText: Observable<String> = domainChangedProperty
      .map {
        let text = $0.replacingOccurrences(of: " ", with: "-").lowercased()
        if text.isEmpty {
          previousDomainText.accept(text)
          isDomainValid.onNext(false)
          return text
        } else if isValidDomain(text) {
          previousDomainText.accept(text)
          checkDomain.onNext(text)
          return text
        }
        checkDomain.onNext(previousDomainText.value)
        return previousDomainText.value
      }
      .share(replay: 1)

    domainText = Observable.merge(initialSubdomain, editedDomainText)
    domainBase = Observable.just(AppEnvironment.current.apiService.serverConfig.providerDomain)

    let domain = Observable
      .merge(initialSubdomain, domainText)
      .map { $0 + "." + AppEnvironment.current.apiService.serverConfig.providerDomain }

    shouldDismiss = didPressDismissProperty
      .withLatestFrom(
        Observable.combineLatest(initialSubdomain, domainText)
          .map { return ($0.0 != $0.1) }
    )

    shouldSubmit = submitButtonPressedProperty.withLatestFrom(domain)

    self.isLoading = isLoading
      .distinctUntilChanged()
      .asObservable()

    self.isDomainValid = isDomainValid
    isEditing = domainChangedProperty.map { _ in () }

    showKeyboard = Observable.merge(
      viewWillAppearProperty.map { _ in true },
      didDismissProperty.map { _ in false }
    )

    Observable.combineLatest(checkDomain, initialSubdomain)
      .do(onNext: { _ in isLoading.accept(true) })
      .debounce(0.3, scheduler: AppEnvironment.current.mainScheduler)
      .flatMapLatest { args -> Observable<Bool> in
        if args.0 == args.1 { return .just(true) }
        let domain = args.0 + "." + AppEnvironment.current.apiService.serverConfig.providerDomain
        return AppEnvironment.current.apiService.domainAvailable(domain: domain)
      }
      .subscribe(onNext: {
        isLoading.accept(false)
        isDomainValid.onNext($0)
      }, onError: { _ in
        isLoading.accept(false)
      })
      .disposed(by: disposeBag)

    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedShopEditionDomain() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let submitButtonPressedProperty = PublishSubject<Void>()
  public func submitButtonPressed() {
    self.submitButtonPressedProperty.onNext(())
  }

  private let domainChangedProperty = PublishSubject<String>()
  public func domainChanged(_ domain: String) {
    self.domainChangedProperty.onNext(domain)
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

  private let deleteBackwardProperty = PublishSubject<String>()
  public func deleteBackward(text: String) {
    self.deleteBackwardProperty.onNext(text)
  }

  private let configureWithProperty = BehaviorRelay<String>(value: "")
  public func configureWith(domain: String) {
    self.configureWithProperty.accept(domain)
  }

  // MARK: - Outputs

  public var domainText: Observable<String>
  public var domainBase: Observable<String>
  public var shouldSubmit: Observable<String>
  public var shouldDismiss: Observable<Bool>
  public var showKeyboard: Observable<Bool>
  public var isLoading: Observable<Bool>
  public var isDomainValid: Observable<Bool>
  public var isEditing: Observable<Void>
}

private func isValidDomain(_ text: String) -> Bool {
  let nsstring = text as NSString
  let pattern = "^[a-z0-9](?:[a-z0-9\\-]{0,62})?$"
  guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
    return false
  }
  let match = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsstring.length))
  return !match.isEmpty
}
