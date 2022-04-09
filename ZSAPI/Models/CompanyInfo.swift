public struct CompanyInfo {
  public let name: String?
  public let logo: Visual?

  public init(name: String? = nil, logo: Visual? = nil) {
    self.name = name
    self.logo = logo
  }
}

extension CompanyInfo: Equatable {}
extension CompanyInfo: Codable {}
