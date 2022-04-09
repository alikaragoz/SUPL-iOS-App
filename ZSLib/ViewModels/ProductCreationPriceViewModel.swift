import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductCreationPriceViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductCreationPriceViewModelOutputs {}

public protocol ProductCreationPriceViewModelType {
  var inputs: ProductCreationPriceViewModelInputs { get }
  var outputs: ProductCreationPriceViewModelOutputs { get }
}

public class ProductCreationPriceViewModel: ProductCreationPriceViewModelType,
  ProductCreationPriceViewModelInputs,
ProductCreationPriceViewModelOutputs {

  public var inputs: ProductCreationPriceViewModelInputs { return self }
  public var outputs: ProductCreationPriceViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedCreateProductPrice() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
