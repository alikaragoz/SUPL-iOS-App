import UIKit

extension UIAlertController {

  public static func universalActionSheet(title: String? = nil, message: String? = nil) -> UIAlertController {
    let alertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: AppEnvironment.current.device.isPad ? .alert : .actionSheet
    )
    return alertController
  }

  public static func confirmationAlert(title: String? = nil,
                                       message: String? = nil,
                                       actionTitle: String,
                                       cancelTitle: String,
                                       completion: @escaping (Bool) -> Void) -> UIAlertController {

    let alertController = UIAlertController.universalActionSheet(title: title, message: message)

    let deleteAction = UIAlertAction(title: actionTitle, style: .destructive) { _ in completion(true) }
    alertController.addAction(deleteAction)

    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in completion(false) }
    alertController.addAction(cancelAction)

    return alertController
  }
}
