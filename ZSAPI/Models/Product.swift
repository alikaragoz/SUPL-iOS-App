public struct Product {
  public let id: String
  public let kind: String = "product"
  public let name: String
  public let priceInfo: PriceInfo
  public let shortDescription: String?
  public let description: String?
  public let disabled: Bool?
  public let stock: Stock?
  public let visuals: [Visual]

  public init(id: String,
              name: String,
              priceInfo: PriceInfo,
              shortDescription: String? = nil,
              description: String? = nil,
              disabled: Bool? = nil,
              stock: Stock? = nil,
              visuals: [Visual]) {
    self.id = id
    self.name = name
    self.priceInfo = priceInfo
    self.shortDescription = shortDescription
    self.description = description
    self.disabled = disabled
    self.stock = stock
    self.visuals = visuals
  }
}

extension Product: Equatable {}
extension Product: Codable {}

public struct ProductUrlResponse {
  public let url: URL
  
  public init(url: URL) {
    self.url = url
  }
}

extension ProductUrlResponse: Equatable {}
extension ProductUrlResponse: Codable {}

public struct ProductStock {
  public let value: Int

  public init(value: Int) {
    self.value = value
  }
}

extension ProductStock: Equatable {}
extension ProductStock: Codable {}
