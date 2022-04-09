import ZSAPI

extension Shop {
  public var editShop: EditShop {
    return EditShop(id: self.id, conf: self.conf?.editConf, domain: self.domain)
  }
}
