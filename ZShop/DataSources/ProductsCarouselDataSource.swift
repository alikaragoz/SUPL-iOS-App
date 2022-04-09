import Foundation
import ZSAPI
import ZSLib

internal final class ProductsCarouselDataSource: ValueCellDataSource {

  weak var carousel: ProductsCarousel?

  internal enum Section: Int {
    case products
  }

  internal override func registerClasses(collectionView: UICollectionView?) {
    collectionView?.registerCellClass(ProductCell.self)
    collectionView?.registerCellClass(ProductAddCell.self)
  }

  internal func load(products: [Product]) {
    self.clearValues()
    self.set(values: products, cellClass: ProductCell.self, inSection: Section.products.rawValue)
    self.appendRow(value: (), cellClass: ProductAddCell.self, toSection: Section.products.rawValue)
  }

  internal func add(product: Product) {
    self.insertRow(
      value: product,
      cellClass: ProductCell.self,
      atIndex: self.numberOfItems() - 1 /* ← AddCell */,
      inSection: Section.products.rawValue
    )
  }

  internal func replace(product: Product, atIndex index: Int) {
    self.set(
      value: product,
      cellClass: ProductCell.self,
      inSection: Section.products.rawValue,
      row: index
    )
  }

  internal override func configureCell(collectionCell cell: UICollectionViewCell, withValue value: Any) {
    switch (cell, value) {
    case let (cell as ProductCell, value as Product):
      cell.configureWith(value: value)
      cell.delegate = carousel
    case let (cell as ProductAddCell, _):
      cell.delegate = carousel
      return
    default:
      assertionFailure("Unrecognized combo: \(cell), \(value).")
    }
  }
}
