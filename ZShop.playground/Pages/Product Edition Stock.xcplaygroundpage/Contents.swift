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

let stock = ProductStock(type: .value, amount: 99)
let vc = ProductEditionStock.configuredWith(shopId: "dead_beef", productId: "dead_beef", stock: stock)
let (parent, child) = playgroundControllers(device: .phone4_7inch, orientation: .portrait, child: vc)
PlaygroundPage.current.liveView = parent
