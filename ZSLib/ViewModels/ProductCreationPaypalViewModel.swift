import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol ProductCreationPaypalViewModelInputs {
  // call when back button is pressed
  func backButtonPressed()
  
  // call when the close button is pressed
  func closeButtonPressed()
  
  // call when the paypal button is pressed
  func paypalButtonPressed()
  
  // call when the skip button is pressed
  func skipButtonPressed()
  
  // call when the view did appear
  func viewDidAppear()
  
  // call when the paypal connect did succeed
  func paypalConnectDidSucceed()
  
  // call when the paypal connect did fail
  func paypalConnectDidFail(_ error: Error)
}

public protocol ProductCreationPaypalViewModelOutputs {
  // emits when the vc should be dismissed
  var shouldDismiss: Observable<Void> { get }
  
  // emits when the next button has been pressed
  var shouldGoToNext: Observable<Void> { get }
  
  // emits when the paypal connection should start
  var shouldStartPaypalConnect: Observable<Void> { get }
  
  // emits when the previous button has been pressed
  var shouldGoToPrevious: Observable<Void> { get }
  
  // emits when the skip button has been pressed
  var shouldSkip: Observable<Void> { get }
  
  // emits whent wif the paypal connect fails
  var paypalConnectDidFail: Observable<Error> { get }
}

public protocol ProductCreationPaypalViewModelType {
  var inputs: ProductCreationPaypalViewModelInputs { get }
  var outputs: ProductCreationPaypalViewModelOutputs { get }
}

public final class ProductCreationPaypalViewModel: ProductCreationPaypalViewModelType,
  ProductCreationPaypalViewModelInputs,
ProductCreationPaypalViewModelOutputs {
  
  public var inputs: ProductCreationPaypalViewModelInputs { return self }
  public var outputs: ProductCreationPaypalViewModelOutputs { return self }
  
  private let disposeBag = DisposeBag()
  
  public init() {
    skipButtonPressedProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackSkippedPaypalDuringCreation() }
      .disposed(by: disposeBag)
    
    shouldDismiss = closeButtonPressedProperty
    shouldGoToNext = paypalConnectDidSucceedProperty
    shouldGoToPrevious = backButtonPressedProperty
    shouldSkip = skipButtonPressedProperty
    shouldStartPaypalConnect = paypalButtonPressedProperty
    paypalConnectDidFail = paypalConnectDidFailProperty
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedCreateProductPaypal() }
      .disposed(by: disposeBag)
  }
  
  // MARK: - Inputs
  
  private let backButtonPressedProperty = PublishSubject<Void>()
  public func backButtonPressed() {
    self.backButtonPressedProperty.onNext(())
  }
  
  private let closeButtonPressedProperty = PublishSubject<Void>()
  public func closeButtonPressed() {
    self.closeButtonPressedProperty.onNext(())
  }
  
  private let paypalButtonPressedProperty = PublishSubject<Void>()
  public func paypalButtonPressed() {
    self.paypalButtonPressedProperty.onNext(())
  }
  
  private let skipButtonPressedProperty = PublishSubject<Void>()
  public func skipButtonPressed() {
    self.skipButtonPressedProperty.onNext(())
  }
  
  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }
  
  private let paypalConnectDidSucceedProperty = PublishSubject<Void>()
  public func paypalConnectDidSucceed() {
    self.paypalConnectDidSucceedProperty.onNext(())
  }
  
  private let paypalConnectDidFailProperty = PublishSubject<Error>()
  public func paypalConnectDidFail(_ error: Error) {
    self.paypalConnectDidFailProperty.onNext(error)
  }
  
  // MARK: - Outputs
  
  public var shouldStartPaypalConnect: Observable<Void>
  public var shouldGoToPrevious: Observable<Void>
  public var shouldGoToNext: Observable<Void>
  public var shouldDismiss: Observable<Void>
  public var shouldSkip: Observable<Void>
  public var paypalConnectDidFail: Observable<Error>
}
