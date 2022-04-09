import ZSAPI

extension Product {
  public var editProduct: EditProduct {
    return EditProduct(
      id: self.id,
      name: self.name,
      description: self.description,
      disabled: self.disabled,
      priceInfo: self.priceInfo,
      pictures: self.visuals.map { $0.editPicture },
      stock: self.stock?.editStock ?? EditStock(type: .unmanaged)
    )
  }
}
