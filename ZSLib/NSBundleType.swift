import Foundation

public enum SUPLBundleIdentifier: String {
  case debug = "com.supl.debug"
  case local = "com.supl.local"
  case release = "com.supl.release"
}

public protocol NSBundleType {
  var bundleIdentifier: String? { get }
  var infoDictionary: [String: Any]? { get }
  func localizedString(forKey key: String, value: String?, table tableName: String?) -> String
  func path(forResource name: String?, ofType ext: String?) -> String?
}

extension NSBundleType {
  public var identifier: String {
    return self.infoDictionary?["CFBundleIdentifier"] as? String ?? "Unknown"
  }
  
  public var shortVersionString: String {
    return self.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }
  
  public var version: String {
    return self.infoDictionary?["CFBundleVersion"] as? String ?? "0"
  }
  
  public var isDebug: Bool {
    return self.identifier == SUPLBundleIdentifier.debug.rawValue
  }

  public var isLocal: Bool {
    return self.identifier == SUPLBundleIdentifier.local.rawValue
  }
  
  public var isRelease: Bool {
    return self.identifier == SUPLBundleIdentifier.release.rawValue
  }
}

extension Bundle: NSBundleType {}
