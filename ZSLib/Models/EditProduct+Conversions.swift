import ZSAPI

extension EditProduct {
  public var product: Product? {
    guard let name = self.name, let priceInfo = self.priceInfo else {
      return nil
    }

    let pictures = self.pictures ?? []
    let visuals = pictures.map { $0.visual }.compactMap { $0 }

    return Product(
      id: self.id,
      name: name,
      priceInfo: priceInfo,
      description: self.description,
      disabled: self.disabled,
      stock: self.stock?.stock,
      visuals: visuals
    )
  }
}
