import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ProductReviewViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductReviewViewModelOutputs {}

public protocol ProductReviewViewModelType {
  var inputs: ProductReviewViewModelInputs { get }
  var outputs: ProductReviewViewModelOutputs { get }
}

public class ProductReviewViewModel: ProductReviewViewModelType,
  ProductReviewViewModelInputs,
ProductReviewViewModelOutputs {

  public var inputs: ProductReviewViewModelInputs { return self }
  public var outputs: ProductReviewViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedProductReview() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
