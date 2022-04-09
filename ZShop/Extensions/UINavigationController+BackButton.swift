import UIKit

@objc public protocol UINavigationBarBackButtonHandler {
  func shouldPopOnBackButton() -> Bool
}

extension UINavigationController: UINavigationBarDelegate {
  public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
    guard let items = navigationBar.items else {
      return false
    }

    if viewControllers.count < items.count {
      return true
    }

    var shouldPop = true
    if let vc = topViewController {
      shouldPop = vc.shouldPopOnBackButton()
    }

    if shouldPop {
      DispatchQueue.main.async { self.popViewController(animated: true) }
    } else {
      navigationBar.subviews
        .filter { $0.alpha > 0 && $0.alpha < 1 }
        .forEach { $0.alpha = 1.0 }
    }
    return false
  }
}

extension UIViewController: UINavigationBarBackButtonHandler {
  public func shouldPopOnBackButton() -> Bool {
    return true
  }
}
