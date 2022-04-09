import UIKit

extension UIImage {
  public func scaled(to size: CGSize) -> UIImage {
    assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")

    UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0.0)
    draw(in: CGRect(origin: .zero, size: size))

    let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
    UIGraphicsEndImageContext()

    return scaledImage
  }

  public func scaled(toLongEdge edge: CGFloat) -> UIImage {
    assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")
    if size.width <= edge && size.height <= edge { return self }

    var scaledSize: CGSize

    if size.width > size.height {
      scaledSize = CGSize(width: edge, height: size.height * (edge / size.width))
    } else {
      scaledSize = CGSize(width: size.width * (edge / size.height), height: edge)
    }

    return scaled(to: scaledSize)
  }
}
