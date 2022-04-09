public struct Stock {
  public enum `Type`: String, Codable {
    case unmanaged
    case supl
  }

  public let type: Type

  public init(type: Type) {
    self.type = type
  }
}

extension Stock: Equatable {}
extension Stock: Codable {}
