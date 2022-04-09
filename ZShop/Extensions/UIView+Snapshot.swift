import UIKit

extension UIView {
  func snapshot() -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, isOpaque, 0)
    drawHierarchy(in: self.bounds, afterScreenUpdates: true)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}
