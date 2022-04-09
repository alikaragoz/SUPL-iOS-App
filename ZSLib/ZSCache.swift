import Foundation

public final class ZSCache {
  private let cache = NSCache<NSString, AnyObject>()

  public static let zs_product_urls = "product_urls"
  public static let zs_product_stocks = "product_stocks"
  public static let zs_product_cloudflare_thumbs = "zs_product_cloudflare_thumbs"

  public init() {
  }
  
  public subscript(key: String) -> Any? {
    get {
      return self.cache.object(forKey: key as NSString)
    }
    set {
      if let newValue = newValue {
        self.cache.setObject(newValue as AnyObject, forKey: key as NSString)
      } else {
        self.cache.removeObject(forKey: key as NSString)
      }
    }
  }
  
  public func removeAllObjects() {
    self.cache.removeAllObjects()
  }

  public func removeCacheFor(key: String) {
    self.cache.removeObject(forKey: key as NSString)
  }
}
