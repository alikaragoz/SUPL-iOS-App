import ZSAPI

extension EditShop {
  public var shop: Shop {
    return Shop(id: self.id, conf: self.conf?.conf, domain: self.domain)
  }
}
