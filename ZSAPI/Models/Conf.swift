public struct Conf {
  public let companyInfo: CompanyInfo?
  public let lang: String?
  public let products: [Product]

  public init(companyInfo: CompanyInfo? = nil,
              lang: String? = Locale.preferredLanguages.first ?? "en-EN",
              products: [Product]) {
    self.companyInfo = companyInfo
    self.lang = lang
    self.products = products
  }
}

extension Conf: Equatable {}
extension Conf: Codable {}
