import Foundation
import ZSAPI
import ZSLib

internal final class CurrencySelectionDataSource: ValueCellDataSource {

  internal enum Section: Int {
    case currencies
  }

  internal override func registerClasses(tableView: UITableView?) {
    tableView?.registerCellClass(CurrencySelectionCell.self)
  }

  internal func load(currencies: [Currency]) {
    self.clearValues()
    self.set(
      values: currencies,
      cellClass: CurrencySelectionCell.self,
      inSection: Section.currencies.rawValue
    )
  }
  
  internal override func configureCell(tableCell cell: UITableViewCell, withValue value: Any) {
    switch (cell, value) {
    case let (cell as CurrencySelectionCell, value as Currency):
      cell.configureWith(value: value)
    default:
      assertionFailure("Unrecognized combo: \(cell), \(value).")
    }
  }
}
