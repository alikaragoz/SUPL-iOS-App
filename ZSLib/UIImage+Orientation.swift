import UIKit

extension UIImage {
  var orientationFixed: UIImage? {
    guard let cgRef = self.cgImage else {
      log("Can't get cgImage from image")
      return nil
    }
    return UIImage(cgImage: cgRef, scale: self.scale, orientation: .up)
  }
}
