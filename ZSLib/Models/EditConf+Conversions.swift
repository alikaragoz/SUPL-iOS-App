import ZSAPI

extension EditConf {
  public var conf: Conf {
    let products = self.products.compactMap { $0.product }
    return Conf(
      companyInfo: self.companyInfo?.companyInfo,
      lang: self.lang,
      products: products)
  }
}
