import ImageIO
import UIKit
import PlaygroundSupport
import RxCocoa
import RxSwift
@testable import ZSAPI
@testable import ZSLib
@testable import ZShop_Framework

let defaults = MockKeyValueStore()
defaults.shop = Shop.Templates.fromUpdate

AppEnvironment.replaceCurrentEnvironment(
  apiService: MockService(),
  mainBundle: Bundle.framework,
  userDefaults: defaults
)

initialize()

let vc = HomeViewController.instance()
let nc = UINavigationController(rootViewController: vc)
nc.navigationBar.prefersLargeTitles = true
let (parent, child) = playgroundControllers(device: .phone4_7inch, orientation: .portrait, child: nc)
PlaygroundPage.current.liveView = parent
