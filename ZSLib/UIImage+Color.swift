import UIKit

extension UIImage {
  public var containsAlphaComponent: Bool {
    let alphaInfo = cgImage?.alphaInfo
    
    return (
      alphaInfo == .first ||
        alphaInfo == .last ||
        alphaInfo == .premultipliedFirst ||
        alphaInfo == .premultipliedLast
    )
  }
  
  public var isOpaque: Bool { return !containsAlphaComponent }
  
  public static func pixel(ofColor color: UIColor) -> UIImage {
    let pixel = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    
    UIGraphicsBeginImageContext(pixel.size)
    defer { UIGraphicsEndImageContext() }
    
    guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
    
    context.setFillColor(color.cgColor)
    context.fill(pixel)
    
    return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
  }
  
  public func fillAlphaWith(fillColor color: UIColor) -> UIImage {
    if isOpaque { return self }
    
    UIGraphicsBeginImageContext(size)
    defer { UIGraphicsEndImageContext() }
    
    guard
      let context = UIGraphicsGetCurrentContext(),
      let cgImage = self.cgImage else {
        return self
    }
    
    let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
    
    // correctly rotate image
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1.0, y: -1.0)
    
    // fill with the color
    context.setBlendMode(.normal)
    color.setFill()
    context.fill(rect)
    
    // mask by alpha values of original image
    context.setBlendMode(.multiply)
    context.draw(cgImage, in: rect)
    
    let img = UIGraphicsGetImageFromCurrentImageContext() ?? self
    return img
  }
}
