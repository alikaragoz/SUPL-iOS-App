import PlaygroundSupport
import Foundation
import UIKit
import ZSPrelude
import ZSLib
import RxCocoa
import RxSwift

PlaygroundPage.current.needsIndefiniteExecution = true

internal struct Request: Codable {
  internal var conf: String
  internal var domain: String?

  internal init(conf: String, domain: String? = nil) {
    self.conf = conf
    self.domain = domain
  }
}

extension Request: Equatable {}

let toEncode1 = Request(conf: "Dead Beef", domain: nil)
let toEncode2 = Request(conf: "Dead Beef", domain: "https://mydomain.co")
let jsonEncoder = JSONEncoder()

let encoded1 = try jsonEncoder.encode(toEncode1)
let encoded2 = try jsonEncoder.encode(toEncode2)

String(data: encoded1, encoding: .utf8)
String(data: encoded2, encoding: .utf8)
