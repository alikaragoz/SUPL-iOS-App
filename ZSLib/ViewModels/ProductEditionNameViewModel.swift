import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductEditionNameViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductEditionNameViewModelOutputs {}

public protocol ProductEditionNameViewModelType {
  var inputs: ProductEditionNameViewModelInputs { get }
  var outputs: ProductEditionNameViewModelOutputs { get }
}

public class ProductEditionNameViewModel: ProductEditionNameViewModelType,
  ProductEditionNameViewModelInputs,
ProductEditionNameViewModelOutputs {

  public var inputs: ProductEditionNameViewModelInputs { return self }
  public var outputs: ProductEditionNameViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedEditProductName() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
