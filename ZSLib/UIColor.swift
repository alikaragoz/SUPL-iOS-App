import class UIKit.UIColor

public extension UIColor {
  @nonobjc public static func hexa(_ value: UInt32) -> UIColor {
    let a = CGFloat((value & 0xFF000000) >> 24) / 255.0
    let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((value & 0xFF00) >> 8) / 255.0
    let b = CGFloat((value & 0xFF)) / 255.0
    
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }
  
  @nonobjc public static func hex(_ value: UInt32) -> UIColor {
    let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((value & 0xFF00) >> 8) / 255.0
    let b = CGFloat((value & 0xFF)) / 255.0
    
    return UIColor(red: r, green: g, blue: b, alpha: 1.0)
  }
  
  public var hexString: String {
    guard let components = self.cgColor.components else { return "000000" }
    let r = components[0]
    let g = components[1]
    let b = components[2]
    return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
  }
  
  public func withBrightnessDelta(_ delta: CGFloat) -> UIColor {
    var hue = CGFloat(0), brightness = CGFloat(0), alpha = CGFloat(0), saturation = CGFloat(0)
    getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
    return type(of: self)
      .init(hue: hue, saturation: saturation, brightness: brightness + delta, alpha: alpha)
  }
}
