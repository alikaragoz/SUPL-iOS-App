import ZSAPI

public struct EditConf {
  public var companyInfo: EditCompanyInfo?
  public var lang: String?
  public var products: [EditProduct]

  public init(companyInfo: EditCompanyInfo? = EditCompanyInfo(),
              lang: String? = nil,
              products: [EditProduct]) {
    self.companyInfo = companyInfo
    self.lang = lang
    self.products = products
  }
}

extension EditConf: Equatable {}
