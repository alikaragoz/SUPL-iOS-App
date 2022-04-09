import UIKit

public final class HomeNavigationController: UINavigationController {

  // MARK: - Init

  convenience init() {
    self.init(nibName: nil, bundle: nil)
  }

  override public init(rootViewController: UIViewController) {
    super.init(rootViewController: rootViewController)
    self.setup()
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }

  private func setup() {
    self.navigationBar.prefersLargeTitles = true
  }
}
