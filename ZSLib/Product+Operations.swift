import ZSAPI

extension Array where Element == Product {
  public func adding(product: Product) -> [Product] {
    return self + [product]
  }

  public func replacing(product: Product, at index: Int) -> [Product] {
    var p = self
    p[index] = product
    return p
  }

  public func removing(atIndex index: Int) -> [Product] {
    var p = self
    p.remove(at: index)
    return p
  }
}
