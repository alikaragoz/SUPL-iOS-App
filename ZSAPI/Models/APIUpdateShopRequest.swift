internal struct APIUpdateShopRequest {
  internal var conf: Conf
  internal var domain: String?

  internal init(conf: Conf, domain: String? = nil) {
    self.conf = conf
    self.domain = domain
  }
}

extension APIUpdateShopRequest: Equatable {}
extension APIUpdateShopRequest: Codable {}

extension APIUpdateShopRequest {
  public init?(shop: Shop) {
    guard let conf = shop.conf else { return nil }
    self.init(conf: conf, domain: shop.domain)
  }
}
