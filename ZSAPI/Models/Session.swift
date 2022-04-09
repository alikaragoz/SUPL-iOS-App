public protocol SessionType {
  var id: String { get }
  var user: String? { get }
}

public struct Session: SessionType {
  public let id: String
  public let user: String?

  public init(id: String, user: String?) {
    self.id = id
    self.user = user
  }
}

extension Session: Codable {}

public func == (lhs: SessionType, rhs: SessionType) -> Bool {
  return type(of: lhs) == type(of: rhs) &&
    lhs.id == rhs.id
}

public func == (lhs: SessionType?, rhs: SessionType?) -> Bool {
  return type(of: lhs) == type(of: rhs) &&
    lhs?.id == rhs?.id
}

public struct PaypalLoginAuthResponse {
  public let userId: String
  public let session: String

  public init(userId: String, session: String) {
    self.session = session
    self.userId = userId
  }
}

extension PaypalLoginAuthResponse: Equatable {}
extension PaypalLoginAuthResponse: Codable {}
