import UIKit

// swiftlint:disable force_cast
extension UITableView {
  func registerClass(_ cellClass: AnyClass) {
    self.register(cellClass, forCellReuseIdentifier: UITableViewCell.reuseIdentifier(cellClass))
  }
  
  func dequeueReusableCell<T: UITableViewCell>(forIndexPath indexPath: IndexPath) -> T {
    return self.dequeueReusableCell(
      withIdentifier: UITableViewCell.reuseIdentifier(T.self),
      for: indexPath) as! T
  }
}

extension UITableViewCell {
  static func reuseIdentifier(_ className: AnyClass) -> String {
    return Bundle.main.bundleIdentifier! + "." + String(describing: className)
  }
}
