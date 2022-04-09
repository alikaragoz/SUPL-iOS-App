import ImageIO
import UIKit
import PlaygroundSupport
import RxCocoa
import RxSwift
@testable import ZSAPI
@testable import ZSLib
@testable import ZShop_Framework

AppEnvironment.replaceCurrentEnvironment(mainBundle: Bundle.framework)

initialize()

let vc = ProductEdition.configuredWith(editProduct: Product.template.editProduct)
let (parent, child) = playgroundControllers(device: .phone4_7inch, orientation: .portrait, child: vc)
PlaygroundPage.current.liveView = parent
