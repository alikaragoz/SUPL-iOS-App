import Foundation
import RxCocoa
import RxSwift
import UIKit

public final class Keyboard {
  private var changeObserver = BehaviorSubject<Change>(value:
    (CGRect.zero,
     0.0,
     UIView.AnimationOptions.curveEaseIn,
     Notification.Name(rawValue: ""))
  )
  
  public typealias Change = (frame: CGRect, duration: TimeInterval, options: UIView.AnimationOptions,
    notificationName: Notification.Name)
  
  public static let shared = Keyboard()
  
  public static var change: BehaviorSubject<Change> {
    return self.shared.changeObserver
  }
  
  private init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(change(_:)),
      name: UIResponder.keyboardWillShowNotification, object: nil)
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(change(_:)),
      name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  @objc private func change(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
      let curveNumber = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber,
      let curve = UIView.AnimationCurve(rawValue: curveNumber.intValue)
      else {
        return
    }
    
    let value = (frame.cgRectValue,
                 duration.doubleValue,
                 UIView.AnimationOptions(rawValue: UInt(curve.rawValue)),
                 notificationName: notification.name)
    
    changeObserver.onNext(value)
  }
}
