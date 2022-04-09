import UIKit

extension UIButton {

  // Sets the background for the defined state
  public func setBackgroundColor(_ backgroundColor: UIColor, for state: UIControl.State) {
    self.setBackgroundImage(.pixel(ofColor: backgroundColor), for: state)
  }

  // Centers the text and the image with the defines spacing
  public func centerTextImage(interSpacing: CGFloat, margin m: CGFloat) {
    let insetAmount = interSpacing / 2
    imageEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
    titleEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
    contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount + m, bottom: 0, right: insetAmount + m)
    semanticContentAttribute = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
      ? .forceLeftToRight
      : .forceRightToLeft
  }

  public func centerImageText(interSpacing: CGFloat, margin m: CGFloat) {
    let insetAmount = interSpacing / 2
    imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
    titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
    contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount + m, bottom: 0, right: insetAmount + m)
  }
}
