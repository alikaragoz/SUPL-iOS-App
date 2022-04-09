import Alamofire
import RxSwift
import ZSPrelude

public protocol ServiceType {
  var appId: String { get }
  var buildVersion: String { get }
  var language: String { get }
  var serverConfig: ServerConfigType { get }
  var session: SessionType? { get }

  init(appId: String,
       buildVersion: String,
       language: String,
       serverConfig: ServerConfigType,
       session: SessionType?)

  // returns a new service with the session replaced
  func login(_ session: SessionType) -> Self

  // returns a new service with the session set to `nil`
  func logout() -> Self

  // creates a shop
  func createShop() -> Observable<Shop>

  // gets a shop
  func getShop(shopId: String) -> Observable<Shop>

  // creates a media
  func createMedia(shopId id: String, mediaType type: MediaType) -> Observable<FileUploadRequest>

  // check a domain availability
  func domainAvailable(domain: String) -> Observable<Bool>

  // get the url of the specified product in the specified shop
  func getProductUrl(productId: String, shopId: String) -> Observable<ProductUrlResponse>

  // gets the stock of the specified product in the specific shop
  func getProductStock(productId: String, shopId: String) -> Observable<ProductStock>

  // login with via a paypal connect
  func loginWithPaypal(params: [String: Any]) -> Observable<Session>

  // assign user to an anonymous shop
  func assignUser(shopId id: String) -> Observable<Void>

  // updates the shop referenced under the id and updates it with the new shop
  func update(shop: Shop) -> Observable<Void>

  // updates the stock for the product / shop combo
  func updateStock(productId: String, shopId: String, amount: Int) -> Observable<Void>
}

extension ServiceType {
  /// Returns `true` if a session is present, and `false` otherwise.
  public var isAuthenticated: Bool {
    return self.session != nil
  }
}

public func == (lhs: ServiceType, rhs: ServiceType) -> Bool {
  return
    type(of: lhs) == type(of: rhs) &&
      lhs.buildVersion == rhs.buildVersion &&
      lhs.language == rhs.language &&
      lhs.serverConfig == rhs.serverConfig &&
      lhs.session == rhs.session
}

public func != (lhs: ServiceType, rhs: ServiceType) -> Bool {
  return !(lhs == rhs)
}

extension ServiceType {
  public var defaultHeaders: [String: String] {
    var headers: [String: String] = [:]
    headers["Accept-Language"] = self.language
    headers["Authorization"] = self.authorizationHeader
    headers["SUPL-App-Id"] = self.appId
    headers["SUPL-iOS-App"] = self.buildVersion
    headers["User-Agent"] = Self.userAgent
    return headers
  }

  public static var userAgent: String {
    let executable = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String
    let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
    let app: String = executable ?? bundleIdentifier ?? "SUPL"
    let bundleVersion: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
    let model = UIDevice.current.model
    let systemVersion = UIDevice.current.systemVersion
    let scale = UIScreen.main.scale
    return "\(app)/\(bundleVersion) (\(model); iOS \(systemVersion) Scale/\(scale))"
  }

  public static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  private var authorizationHeader: String? {
    guard let id = self.session?.id else { return nil }
    return "Bearer \(id)"
  }
}
