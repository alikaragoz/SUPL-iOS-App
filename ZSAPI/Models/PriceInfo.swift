public struct PriceInfo {
  public let amount: Int
  public let currency: String

  public init(
    amount: Int,
    currency: String) {
    self.amount = amount
    self.currency = currency
  }
}

extension PriceInfo: Equatable {}
extension PriceInfo: Codable {}
