import ZSAPI

extension Conf {
  public var editConf: EditConf {
    let editProducts = self.products.map { $0.editProduct }
    return EditConf(
      companyInfo: self.companyInfo?.editCompanyInfo,
      lang: self.lang,
      products: editProducts)
  }
}
