import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol ShopEditionNameViewModelInputs {
  // call when the view did appear
  func viewDidAppear()
}

public protocol ShopEditionNameViewModelOutputs {}

public protocol ShopEditionNameViewModelType {
  var inputs: ShopEditionNameViewModelInputs { get }
  var outputs: ShopEditionNameViewModelOutputs { get }
}

public class ShopEditionNameViewModel: ShopEditionNameViewModelType,
  ShopEditionNameViewModelInputs,
ShopEditionNameViewModelOutputs {

  public var inputs: ShopEditionNameViewModelInputs { return self }
  public var outputs: ShopEditionNameViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedShopEditionName() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs
}
