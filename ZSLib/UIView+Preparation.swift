import UIKit

extension UIView {

  open override func awakeFromNib() {
    super.awakeFromNib()
    self.bindViewModel()
  }

  @objc open func bindViewModel() {
  }

  public static var defaultReusableId: String {
    return self.description()
      .components(separatedBy: ".")
      .dropFirst()
      .joined(separator: ".")
  }
}
