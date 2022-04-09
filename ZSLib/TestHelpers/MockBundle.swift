@testable import ZSLib

internal struct MockBundle: NSBundleType {

  internal let bundleIdentifier: String?

  internal var infoDictionary: [String: Any]? {
    var result: [String: Any] = [:]
    result["CFBundleIdentifier"] = self.bundleIdentifier
    result["CFBundleVersion"] = "1234567890"
    result["CFBundleShortVersionString"] = "1.2.3.4.5.6.7.8.9.0"
    return result
  }

  internal init(bundleIdentifier: String? = "com.bundle.mock") {
    self.bundleIdentifier = bundleIdentifier
  }

  func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
    return "string"
  }

  func path(forResource name: String?, ofType ext: String?) -> String? {
    return name
  }
}
