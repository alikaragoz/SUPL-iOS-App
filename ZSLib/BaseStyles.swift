import UIKit

public struct Styles {
  public static let cornerRadius: CGFloat = 4.0
}

public func roundStyle <V: UIView> (cornerRadius radius: CGFloat = Styles.cornerRadius) -> (V) -> V {
  return {
    $0.layer.cornerRadius = radius
    return $0
  }
}
