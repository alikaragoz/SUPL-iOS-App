import ZSAPI

public struct EditProduct {
  public var id: String
  public var name: String?
  public var description: String?
  public var disabled: Bool?
  public var priceInfo: PriceInfo?
  public var pictures: [EditPicture]?
  public var stock: EditStock?
  
  public init(
    name: String? = nil,
    description: String? = nil,
    disabled: Bool? = nil,
    priceInfo: PriceInfo? = nil,
    pictures: [EditPicture]? = nil,
    stock: EditStock? = EditStock(type: .unmanaged)) {
    self.id = AppEnvironment.current.uuid.uuidString
    self.name = name
    self.description = description
    self.disabled = disabled
    self.priceInfo = priceInfo
    self.pictures = pictures
    self.stock = stock
  }
  
  public init(
    id: String,
    name: String? = nil,
    description: String? = nil,
    disabled: Bool? = nil,
    priceInfo: PriceInfo? = nil,
    pictures: [EditPicture]? = nil,
    stock: EditStock? = EditStock(type: .unmanaged)) {
    self.id = id
    self.name = name
    self.description = description
    self.disabled = disabled
    self.priceInfo = priceInfo
    self.pictures = pictures
    self.stock = stock
  }
}

extension EditProduct: Equatable {}

extension EditProduct {
  public var isValid: Bool {
    return (
      self.name != nil
        && self.priceInfo != nil
        && ((self.pictures?.isEmpty ?? true) == false)
    )
  }
}
