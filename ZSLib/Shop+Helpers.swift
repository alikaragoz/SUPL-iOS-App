import ZSAPI
import RxSwift
import ZSPrelude

public enum ShopChange: Equatable {
  case add(Int)
  case delete(Int)
  case update(Int)
}

public enum ShopError: Error, LocalizedError {
  case couldNotFindProduct
  case couldNotGetConf
  case productIndexMismatch

  public var errorDescription: String? {
    switch self {
    case .couldNotFindProduct: return "couldNotFindProduct"
    case .couldNotGetConf: return "couldNotGetConf"
    case .productIndexMismatch: return "productIndexMismatch"
    }
  }
}

// MARK: - Get / Create

extension Shop {
  public static func getOrCreate() -> Observable<Shop> {
    guard let shop = AppEnvironment.current.userDefaults.shop else {
      return AppEnvironment.current.apiService.createShop()
        .do(onNext: {
          AppEnvironment.current.userDefaults.shop = $0
        })
        .autoRetryOnNetworkError()
        .subscribeOn(AppEnvironment.current.backgroundScheduler)
    }
    return .just(shop)
  }
}

// MARK: - Operation

extension Shop {

  // MARK: - Add

  public func addProduct(_ product: Product) -> Observable<(Product, ShopChange)> {
    var newConf: Conf

    if let conf = self.conf {
      newConf = conf
        |> Conf.lens.products .~ conf.products.adding(product: product)
    } else {
      newConf = Conf(products: [product])
    }

    // Applying the current lang
    let lang = Locale.preferredLanguages.first ?? "en-EN"
    newConf = newConf
      |> Conf.lens.lang .~ lang

    let newShop = self
      |> Shop.lens.conf .~ newConf

    let updateShop = AppEnvironment.current.apiService
      .update(shop: newShop)
      .do(onNext: { _ in
        AppEnvironment.current.userDefaults.shop = newShop
        AppEnvironment.current.analytics.set(shop: newShop)
      })

    log("Add a product named: \(product.name)")

    return updateShop.flatMap { _ in
      return Observable.just((product, .add(newConf.products.count - 1)))
    }
  }

  // MARK: - Update

  public func updateProduct(atIndex index: Int, with product: Product) -> Observable<(Product, ShopChange)> {
    let newConf: Conf

    guard let conf = self.conf else {
      trackRuntimeError("Could not get the conf")
      return .error(ShopError.couldNotGetConf)
    }

    guard index < conf.products.count else {
      trackRuntimeError("Index does not match products count")
      return .error(ShopError.productIndexMismatch)
    }

    let lang = Locale.preferredLanguages.first ?? "en-EN"
    newConf = conf
      |> Conf.lens.products .~ conf.products.replacing(product: product, at: index)
      |> Conf.lens.lang .~ lang

    let newShop = self |> Shop.lens.conf .~ newConf

    let updateShop = AppEnvironment.current.apiService
      .update(shop: newShop)
      .do(onNext: { _ in
        AppEnvironment.current.userDefaults.shop = newShop
        AppEnvironment.current.analytics.set(shop: newShop)
      })

    log("Updating the product named: \(product.name)")

    return updateShop.flatMap { _ in
      return Observable.just((product, .update(index)))
    }
  }

  public func updateProduct(_ product: Product) -> Observable<(Product, ShopChange)> {
    guard let conf = self.conf else {
      trackRuntimeError("Could not get the conf")
      return .error(ShopError.couldNotGetConf)
    }

    guard let index = conf.products.index(where: { $0.id == product.id }) else {
      return .error(ShopError.couldNotFindProduct)
    }

    return updateProduct(atIndex: index, with: product)
  }

  // MARK: - Delete

  public func deleteProduct(atIndex index: Int) -> Observable<(Product, ShopChange)> {
    let newConf: Conf

    guard let conf = self.conf else {
      trackRuntimeError("Could not get the conf")
      return .error(ShopError.couldNotGetConf)
    }

    guard index < conf.products.count else {
      trackRuntimeError("Index does not match products count")
      return .error(ShopError.productIndexMismatch)
    }

    let product = conf.products[index]
    newConf = conf |> Conf.lens.products .~ conf.products.removing(atIndex: index)
    let newShop = self |> Shop.lens.conf .~ newConf

    let updateShop =  AppEnvironment.current.apiService
      .update(shop: newShop)
      .do(onNext: { _ in
        AppEnvironment.current.userDefaults.shop = newShop
        AppEnvironment.current.analytics.set(shop: newShop)
      })

    log("Deleting the product named: \(product.name)")

    return updateShop.flatMap { _ in
      return Observable.just((product, .delete(index)))
    }
  }

  public func deleteProduct(_ product: Product) -> Observable<(Product, ShopChange)> {
    guard let conf = self.conf else {
      trackRuntimeError("Could not get the conf")
      return .error(ShopError.couldNotGetConf)
    }

    guard let index = conf.products.index(where: { $0.id == product.id }) else {
      return .error(ShopError.couldNotFindProduct)
    }

    return deleteProduct(atIndex: index)
  }

  // MARK: - Product Id

  public func getNewProductId() -> String {
    let id = (conf?.products.compactMap { Int($0.id) }.max() ?? 0) + 1
    return String(id)
  }
}
