import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductCreationSaveViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductCreationSaveViewModelOutputs {}

public protocol ProductCreationSaveViewModelType {
  var inputs: ProductCreationSaveViewModelInputs { get }
  var outputs: ProductCreationSaveViewModelOutputs { get }
}

public class ProductCreationSaveViewModel: ProductCreationSaveViewModelType,
  ProductCreationSaveViewModelInputs,
ProductCreationSaveViewModelOutputs {

  public var inputs: ProductCreationSaveViewModelInputs { return self }
  public var outputs: ProductCreationSaveViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedCreateProductSave() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
