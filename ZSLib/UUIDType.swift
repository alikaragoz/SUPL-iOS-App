import UIKit

public protocol UUIDProviderType {
  var uuidString: String { get }
}

internal struct MockUUID: UUIDProviderType {
  internal var uuidString = "MockedUUID"
}

public class UUIDProvider {
  public init() {}
  
  public var uuidString: String {
    return UUID().uuidString
  }
}

extension UUIDProvider: UUIDProviderType {}
