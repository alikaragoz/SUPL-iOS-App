import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol EditableStockViewModelInputs {
  // call to configure
  func configureWith(editStock: EditStock, productId: String, shopId: String)
}

public protocol EditableStockViewModelOutputs {
  // emits the state of the view
  var state: Observable<EditableStockViewModel.State> { get }
}

public protocol EditableStockViewModelType {
  var inputs: EditableStockViewModelInputs { get }
  var outputs: EditableStockViewModelOutputs { get }
}

public class EditableStockViewModel: EditableStockViewModelType,
  EditableStockViewModelInputs,
EditableStockViewModelOutputs {

  public enum State {
    case loading
    case unlimited
    case amount(Int)
  }

  public var inputs: EditableStockViewModelInputs { return self }
  public var outputs: EditableStockViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    let state: Observable<EditableStockViewModel.State> = configureProperty
      .unwrap()
      .flatMap { args -> Observable<EditableStockViewModel.State> in
        switch args.editStock.type {
        case .unmanaged:
          return .just(.unlimited)
        case .supl:
          if let amount = args.editStock.amount {
            return .just(.amount(amount))
          }
          return Product.getFromCacheOrFetchStock(productId: args.productId, shopId: args.shopId)
            .map { .amount($0) }
        }
      }
      .startWith(.loading)

    self.state = state
  }

  // MARK: - Inputs

  private typealias ConfigureParams = (editStock: EditStock, productId: String, shopId: String)
  private let configureProperty = BehaviorRelay<ConfigureParams?>(value: nil)
  public func configureWith(editStock: EditStock, productId: String, shopId: String) {
    self.configureProperty.accept((editStock: editStock, productId: productId, shopId: shopId))
  }

  // MARK: - Outputs
  public var state: Observable<EditableStockViewModel.State>
}
