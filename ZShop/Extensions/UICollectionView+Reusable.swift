import UIKit

// swiftlint:disable force_cast
extension UICollectionView {
  func registerClass(_ cellClass: AnyClass) {
    self.register(cellClass, forCellWithReuseIdentifier: UICollectionViewCell.reuseIdentifier(cellClass))
  }
  
  func dequeueReusableCell<T: UICollectionViewCell>(forIndexPath indexPath: IndexPath) -> T {
    return self.dequeueReusableCell(
      withReuseIdentifier: UICollectionViewCell.reuseIdentifier(T.self),
      for: indexPath) as! T
  }
}

extension UICollectionViewCell {
  static func reuseIdentifier(_ className: AnyClass) -> String {
    return Bundle.main.bundleIdentifier! + "." + String(describing: className)
  }
}
