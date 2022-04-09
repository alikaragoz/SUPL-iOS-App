import ZSAPI

public struct CreatorProduct {
  public var name: String?
  public var priceInfo: PriceInfo?
  public var medias: [Media]?
  
  public init(
    name: String? = nil,
    priceInfo: PriceInfo? = nil,
    medias: [Media]? = nil) {
    self.name = name
    self.priceInfo = priceInfo
    self.medias = medias
  }
}

extension CreatorProduct: Equatable {}
