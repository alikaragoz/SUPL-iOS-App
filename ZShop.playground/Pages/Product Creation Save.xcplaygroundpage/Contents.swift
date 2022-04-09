import ImageIO
import UIKit
import PlaygroundSupport
import RxCocoa
import RxSwift
@testable import ZSAPI
@testable import ZSLib
@testable import ZShop_Framework

PlaygroundPage.current.needsIndefiniteExecution = true

initialize()

let defaults = MockKeyValueStore()
defaults.shop = Shop.Templates.fromUpdate

AppEnvironment.replaceCurrentEnvironment(
  apiService: MockService(),
  mainBundle: Bundle.framework,
  userDefaults: defaults
)

let vc = ProductCreationSave.configuredWith(editProduct: Product.template.editProduct)
let (parent, child) = playgroundControllers(device: .phone4inch, orientation: .portrait, child: vc)
PlaygroundPage.current.liveView = parent

