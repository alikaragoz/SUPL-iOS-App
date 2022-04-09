import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public enum ShopSaveViewModelError: Error, LocalizedError {
  case pictureProcessNotSet

  public var errorDescription: String? {
    switch self {
    case .pictureProcessNotSet: return "pictureProcessNotSet"
    }
  }
}

public protocol ShopSaveViewModelInputs {
  // call to configure
  func configureWith(editShop: EditShop)
}

public protocol ShopSaveViewModelOutputs {
  // emits when the shop has been saved
  var didSave: Observable<Shop> { get }

  // emits when the loader should complete
  var shouldCompleteLoader: Observable<Void> { get }
}

public protocol ShopSaveViewModelType {
  var inputs: ShopSaveViewModelInputs { get }
  var outputs: ShopSaveViewModelOutputs { get }
}

public final class ShopSaveViewModel: ShopSaveViewModelType,
  ShopSaveViewModelInputs,
ShopSaveViewModelOutputs {

  public var inputs: ShopSaveViewModelInputs { return self }
  public var outputs: ShopSaveViewModelOutputs { return self }

  public init() {
    let editShop = self.editShopProp.unwrap().take(1).share(replay: 1)
    let shouldCompleteLoader = PublishSubject<Void>()

    let pictureProcessSignal = editShop.flatMap {
      pictureProcess(editShop: $0)
    }

    didSave = pictureProcessSignal
      .withLatestFrom(editShop)
      .flatMap { es in
        return updateShop(es.shop)
          .map { _ in es }
          .do(onNext: { _ in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            AppEnvironment.current.userDefaults.shop = es.shop
            AppEnvironment.current.analytics.set(shop: es.shop)
          })
      }
      .do(onNext: { _ in shouldCompleteLoader.onNext(()) })
      .map { $0.shop }

    self.shouldCompleteLoader = shouldCompleteLoader
  }

  // MARK: - Inputs

  private let editShopProp = BehaviorRelay<EditShop?>(value: nil)
  public func configureWith(editShop: EditShop) {
    self.editShopProp.accept(editShop)
  }

  // MARK: - Outputs

  public var didSave: Observable<Shop>
  public var shouldCompleteLoader: Observable<Void>
}

// MARK: - Utils

private func updateShop(_ shop: Shop) -> Observable<Void> {
  return AppEnvironment.current.apiService.update(shop: shop)
    .autoRetryOnNetworkError()
    .do(onNext: { _ in
      AppEnvironment.current.analytics.trackSucceededShopEdition(shop: shop)
      AppEnvironment.current.cache.removeCacheFor(key: ZSCache.zs_product_urls)
    })
    .do(onError: { error in
      AppEnvironment.current.analytics.trackErroredShopEdition(
        shop: shop,
        error: error.localizedDescription
      )
    })
}

private func pictureProcess(editShop: EditShop) -> Observable<Void> {
  guard let process = editShop.conf?.companyInfo?.editPicture?.process else {
    return .just(())
  }
  return process.map { _ in () }
}
