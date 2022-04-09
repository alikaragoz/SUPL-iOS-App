import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductEditionPriceViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductEditionPriceViewModelOutputs {}

public protocol ProductEditionPriceViewModelType {
  var inputs: ProductEditionPriceViewModelInputs { get }
  var outputs: ProductEditionPriceViewModelOutputs { get }
}

public class ProductEditionPriceViewModel: ProductEditionPriceViewModelType,
  ProductEditionPriceViewModelInputs,
ProductEditionPriceViewModelOutputs {

  public var inputs: ProductEditionPriceViewModelInputs { return self }
  public var outputs: ProductEditionPriceViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedEditProductPrice() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
