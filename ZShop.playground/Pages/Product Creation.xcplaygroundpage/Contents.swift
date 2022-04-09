import ImageIO
import UIKit
import PlaygroundSupport
import RxCocoa
import RxSwift
import RxTest
@testable import ZSAPI
import ZSLib
@testable import ZShop_Framework

PlaygroundPage.current.needsIndefiniteExecution = true

initialize()

AppEnvironment.replaceCurrentEnvironment(mainBundle: Bundle.framework)

let vc = ProductCreationName.configuredWith(name: "Foo Bar")
let (parent, child) = playgroundControllers(device: .phone4inch, orientation: .portrait, child: vc)
PlaygroundPage.current.liveView = parent
