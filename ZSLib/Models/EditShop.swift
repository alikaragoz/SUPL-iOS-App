import ZSAPI

public struct EditShop {
  public let id: String
  public var conf: EditConf?
  public var domain: String

  public init(id: String,
              conf: EditConf? = nil,
              domain: String) {
    self.id = id
    self.conf = conf
    self.domain = domain
  }
}

extension EditShop: Equatable {}
