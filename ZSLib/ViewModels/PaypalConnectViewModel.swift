import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol PaypalConnectViewModelInputs {
  // call when the close button is pressed
  func closeButtonPressed()
  
  // call when the paypal button is pressed
  func paypalButtonPressed()
  
  // call when the view did appear
  func viewDidAppear()
}

public protocol PaypalConnectViewModelOutputs {
  // emits when the vc should be dismissed
  var shouldDismiss: Observable<Void> { get }

  // emits when the paypal connection should start
  var shouldStartPaypalConnect: Observable<Void> { get }
}

public protocol PaypalConnectViewModelType {
  var inputs: PaypalConnectViewModelInputs { get }
  var outputs: PaypalConnectViewModelOutputs { get }
}

public final class PaypalConnectViewModel: PaypalConnectViewModelType,
  PaypalConnectViewModelInputs,
PaypalConnectViewModelOutputs {
  
  public var inputs: PaypalConnectViewModelInputs { return self }
  public var outputs: PaypalConnectViewModelOutputs { return self }
  
  private let disposeBag = DisposeBag()
  
  public init() {
    shouldDismiss = closeButtonPressedProperty
    shouldStartPaypalConnect = paypalButtonPressedProperty
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedPaypalConnect() }
      .disposed(by: disposeBag)
  }
  
  // MARK: - Inputs
  
  private let closeButtonPressedProperty = PublishSubject<Void>()
  public func closeButtonPressed() {
    self.closeButtonPressedProperty.onNext(())
  }
  
  private let paypalButtonPressedProperty = PublishSubject<Void>()
  public func paypalButtonPressed() {
    self.paypalButtonPressedProperty.onNext(())
  }
  
  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
  
  public var shouldDismiss: Observable<Void>
  public var shouldStartPaypalConnect: Observable<Void>
}
