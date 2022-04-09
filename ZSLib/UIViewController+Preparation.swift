import ObjectiveC
import UIKit

private func swizzle(_ vc: UIViewController.Type) {
  
  [(#selector(vc.viewDidLoad), #selector(vc.zs_viewDidLoad))]
    .forEach { original, swizzled in
      
      guard let originalMethod = class_getInstanceMethod(vc, original),
        let swizzledMethod = class_getInstanceMethod(vc, swizzled) else { return }
      
      let didAddViewDidLoadMethod = class_addMethod(vc,
                                                    original,
                                                    method_getImplementation(swizzledMethod),
                                                    method_getTypeEncoding(swizzledMethod))
      
      if didAddViewDidLoadMethod {
        class_replaceMethod(vc,
                            swizzled,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod))
      } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
      }
  }
}

private var hasSwizzled = false

extension UIViewController {
  final public class func doBadSwizzleStuff() {
    guard !hasSwizzled else { return }
    
    hasSwizzled = true
    swizzle(self)
  }
  
  @objc internal func zs_viewDidLoad() {
    self.zs_viewDidLoad()
    self.bindViewModel()
  }
  
  /**
   The entry point to bind all view model outputs. Called just before `viewDidLoad`.
   */
  @objc open func bindViewModel() {
  }

  public var isPresentingForFirstTime: Bool {
    return isBeingPresented || isMovingToParent
  }
}

extension UIViewController {
  public static var storyboardIdentifier: String {
    return self.description().components(separatedBy: ".").dropFirst().joined(separator: ".")
  }
}
