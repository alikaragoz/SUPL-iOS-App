import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductCreationNameViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductCreationNameViewModelOutputs {}

public protocol ProductCreationNameViewModelType {
  var inputs: ProductCreationNameViewModelInputs { get }
  var outputs: ProductCreationNameViewModelOutputs { get }
}

public class ProductCreationNameViewModel: ProductCreationNameViewModelType,
  ProductCreationNameViewModelInputs,
ProductCreationNameViewModelOutputs {

  public var inputs: ProductCreationNameViewModelInputs { return self }
  public var outputs: ProductCreationNameViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedCreateProductName() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
