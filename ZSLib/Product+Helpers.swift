import ZSAPI
import RxSwift

extension Product {
  
  public static func getFromCacheOrFetchUrl(productId: String, shopId: String) -> Observable<URL> {
    guard
      let productUrlsCache = AppEnvironment.current.cache[ZSCache.zs_product_urls] as? [String: URL],
      let url = productUrlsCache[productId]
      else {
        return AppEnvironment.current.apiService.getProductUrl(productId: productId, shopId: shopId)
          .map { $0.url }
          .do(onNext: {
            AppEnvironment.current.cache[ZSCache.zs_product_urls] =
              AppEnvironment.current.cache[ZSCache.zs_product_urls] ?? [String: URL]()
            
            var productUrlsCache = AppEnvironment.current.cache[ZSCache.zs_product_urls] as? [String: URL]
            productUrlsCache?[productId] = $0
            
            AppEnvironment.current.cache[ZSCache.zs_product_urls] = productUrlsCache
          })
          .autoRetryOnNetworkError()
          .subscribeOn(AppEnvironment.current.backgroundScheduler)
    }
    
    return .just(url)
  }
  
  public static func getFromCacheOrFetchStock(productId: String, shopId: String) -> Observable<Int> {
    guard
      let productStocksCache = AppEnvironment.current.cache[ZSCache.zs_product_stocks] as? [String: Int],
      let amount = productStocksCache[productId]
      else {
        return AppEnvironment.current.apiService.getProductStock(productId: productId, shopId: shopId)
          .map { $0.value }
          .do(onNext: {
            AppEnvironment.current.cache[ZSCache.zs_product_stocks] =
              AppEnvironment.current.cache[ZSCache.zs_product_stocks] ?? [String: Int]()
            
            var productStocksCache = AppEnvironment.current.cache[ZSCache.zs_product_stocks] as? [String: Int]
            productStocksCache?[productId] = $0
            
            AppEnvironment.current.cache[ZSCache.zs_product_stocks] = productStocksCache
          })
          .autoRetryOnNetworkError()
          .subscribeOn(AppEnvironment.current.backgroundScheduler)
    }
    
    return .just(amount)
  }
}
