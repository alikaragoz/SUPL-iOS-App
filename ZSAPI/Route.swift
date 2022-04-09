internal enum Route {
  case assignUser(shopId: String)
  case createMedia(shopId: String, params: [String: Any])
  case createShop
  case domainAvailable(params: [String: Any])
  case getProductStock(productId: String, shopId: String)
  case getProductUrl(productId: String, shopId: String)
  case getShop(shopId: String)
  case loginWithPaypal(params: [String: Any])
  case updateShop(shopId: String, params: [String: Any])
  case updateStock(productId: String, shopId: String, params: [String: Any])

  internal var requestProperties: (method: Method, path: String, params: [String: Any]?) {
    switch self {
    case let .assignUser(shopId):
      return (.POST, "api/v1/shops/\(shopId)/assign_user", nil)
    case let .createMedia(shopId, params):
      return (.POST, "api/v1/shops/\(shopId)/medias", params)
    case .createShop:
      return (.POST, "api/v1/shops", nil)
    case let .domainAvailable(params):
      return (.GET, "api/v1/domains/available", params)
    case let .getProductUrl(productId, shopId):
      return (.GET, "api/v1/shops/\(shopId)/product/\(productId)/url", nil)
    case let .getProductStock(productId, shopId):
      return (.GET, "api/v1/shops/\(shopId)/product/\(productId)/stock", nil)
    case let .getShop(shopId):
      return (.GET, "api/v1/shops/\(shopId)", nil)
    case let .loginWithPaypal(params):
      return (.POST, "api/v1/auth/paypal_secret", params)
    case let .updateShop(shopId, params):
      return (.PATCH, "api/v1/shops/\(shopId)", params)
    case let .updateStock(productId, shopId, params):
      return (.PATCH, "api/v1/shops/\(shopId)/product/\(productId)/stock", params)
    }
  }
}
