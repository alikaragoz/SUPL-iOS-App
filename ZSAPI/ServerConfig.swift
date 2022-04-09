// swiftlint:disable force_unwrapping

public protocol ServerConfigType {
  var apiBaseUrl: URL { get }
  var providerDomain: String { get }
  var environment: EnvironmentType { get }
}

public func == (lhs: ServerConfigType, rhs: ServerConfigType) -> Bool {
  return
    type(of: lhs) == type(of: rhs) &&
      lhs.apiBaseUrl == rhs.apiBaseUrl &&
      lhs.providerDomain == rhs.providerDomain &&
      lhs.environment == rhs.environment
}

public enum EnvironmentType: String, CaseIterable {
  case production = "Production"
  case local = "Local"
}

public struct ServerConfig: ServerConfigType {

  public private(set) var apiBaseUrl: URL
  public private(set) var providerDomain: String
  public private(set) var environment: EnvironmentType

  public static let production: ServerConfigType = ServerConfig(
    apiBaseUrl: URL(string: "https://supl.co")!,
    providerDomain: "supl.co",
    environment: EnvironmentType.production
  )

  public static let local: ServerConfigType = ServerConfig(
    apiBaseUrl: URL(string: "http://\(ipv4_address):4000")!,
    providerDomain: "localhost",
    environment: EnvironmentType.local
  )

  public init(apiBaseUrl: URL,
              providerDomain: String = "supl.co",
              environment: EnvironmentType = .production) {
    self.apiBaseUrl = apiBaseUrl
    self.providerDomain = providerDomain
    self.environment = environment
  }

  public static func config(for environment: EnvironmentType) -> ServerConfigType {
    switch environment {
    case .local: return ServerConfig.local
    case .production: return ServerConfig.production
    }
  }
}
