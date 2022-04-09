import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductEditionDescViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductEditionDescViewModelOutputs {}

public protocol ProductEditionDescViewModelType {
  var inputs: ProductEditionDescViewModelInputs { get }
  var outputs: ProductEditionDescViewModelOutputs { get }
}

public class ProductEditionDescViewModel: ProductEditionDescViewModelType,
  ProductEditionDescViewModelInputs,
ProductEditionDescViewModelOutputs {

  public var inputs: ProductEditionDescViewModelInputs { return self }
  public var outputs: ProductEditionDescViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedEditProductDescription() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
