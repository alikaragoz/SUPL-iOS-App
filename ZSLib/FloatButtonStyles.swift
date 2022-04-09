import UIKit
import ZSPrelude

public extension FloatButton {
  public struct Styles {
    public static let height: CGFloat = 50.0
    public static let cornerRadius: CGFloat = Styles.height / 2.0
  }
}

public var baseFloatButtonStyle: (FloatButton) -> FloatButton = {
  $0.contentEdgeInsets = .init(top: 8, left: 22, bottom: 8, right: 22)
  $0.heightAnchor.constraint(equalToConstant: FloatButton.Styles.height).isActive = true
  $0.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
  return $0
}

var roundFloatButtonStyle: (FloatButton) -> FloatButton =
  roundStyle(cornerRadius: FloatButton.Styles.cornerRadius)

public var greenFloatButtonStyle: (FloatButton) -> FloatButton =
  baseFloatButtonStyle
    <> roundFloatButtonStyle
    <> {
      $0.backgroundColor(.zs_green, for: .normal)
      $0.backgroundColor(UIColor.zs_green.withBrightnessDelta(0.05), for: .highlighted)
      $0.backgroundColor(UIColor.zs_green.withAlphaComponent(0.5), for: .disabled)
      return $0
}

public var grayFloatButtonStyle: (FloatButton) -> FloatButton =
  baseFloatButtonStyle
    <> roundFloatButtonStyle
    <> {
      $0.backgroundColor(.zs_light_gray, for: .normal)
      $0.backgroundColor(UIColor.zs_light_gray.withBrightnessDelta(0.05), for: .highlighted)
      $0.backgroundColor(UIColor.zs_light_gray.withAlphaComponent(0.5), for: .disabled)
      return $0
}

public var blackFloatButtonStyle: (FloatButton) -> FloatButton =
  baseFloatButtonStyle
    <> roundFloatButtonStyle
    <> {
      $0.backgroundColor(.zs_black, for: .normal)
      $0.backgroundColor(UIColor.zs_black.withBrightnessDelta(0.05), for: .highlighted)
      $0.backgroundColor(UIColor.zs_black.withAlphaComponent(0.5), for: .disabled)
      return $0
}

public var paypalFloatButtonStyle: (FloatButton) -> FloatButton =
  baseFloatButtonStyle
    <> roundFloatButtonStyle
    <> {
      $0.backgroundColor(.zs_paypal_yellow, for: .normal)
      $0.backgroundColor(UIColor.zs_paypal_yellow.withBrightnessDelta(0.05), for: .highlighted)
      $0.backgroundColor(UIColor.zs_paypal_yellow.withAlphaComponent(0.5), for: .disabled)
      return $0
}

public var centerTextAndImageFloatButtonStyle: (FloatButton) -> FloatButton = {
  $0.contentEdgeInsets = .init(top: 8, left: 22, bottom: 8, right: 32)
  $0.titleEdgeInsets = .init(top: 0, left: 10, bottom: 0, right: -10)
  return $0
}

public var squareFloatButtonStyle: (FloatButton) -> FloatButton = {
  $0.contentEdgeInsets = .zero
  $0.heightAnchor.constraint(equalToConstant: FloatButton.Styles.height).isActive = true
  $0.widthAnchor.constraint(equalToConstant: FloatButton.Styles.height).isActive = true
  return $0
}
