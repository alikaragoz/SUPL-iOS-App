import Alamofire
import RxSwift

public extension Bundle {
  var _buildVersion: String {
    return (self.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
  }

  var _identifier: String {
    return self.infoDictionary?["CFBundleIdentifier"] as? String ?? "Unknown"
  }

  var _isLocal: Bool {
    return self._identifier == "com.supl.local"
  }
}

public enum ServiceError: Error, LocalizedError {
  case convertionFromStructToDict
  case genericClientError

  public var errorDescription: String? {
    switch self {
    case .convertionFromStructToDict: return "convertionFromStructToDict"
    case .genericClientError: return "genericClientError"
    }
  }
}

public struct Service: ServiceType {
  public let appId: String
  public let language: String
  public let buildVersion: String
  public let serverConfig: ServerConfigType
  public let session: SessionType?

  public init(
    appId: String = Bundle.main.bundleIdentifier ?? "com.supl.release",
    buildVersion: String = Bundle.main._buildVersion,
    language: String = "en",
    serverConfig: ServerConfigType = Bundle.main._isLocal ? ServerConfig.local : ServerConfig.production,
    session: SessionType? = nil) {
    self.appId = appId
    self.buildVersion = buildVersion
    self.language = language
    self.serverConfig = serverConfig
    self.session = session
  }

  public func login(_ session: SessionType) -> Service {
    return Service(appId: self.appId,
                   buildVersion: self.buildVersion,
                   language: self.language,
                   serverConfig: self.serverConfig,
                   session: session)
  }

  public func logout() -> Service {
    return Service(appId: self.appId,
                   buildVersion: self.buildVersion,
                   language: self.language,
                   serverConfig: self.serverConfig,
                   session: nil)
  }

  public func createShop() -> Observable<Shop> {
    return request(.createShop)
  }

  public func createMedia(shopId id: String, mediaType type: MediaType) -> Observable<FileUploadRequest> {
    let params = ["type": type.rawValue]
    return request(Route.createMedia(shopId: id, params: params))
  }

  public func domainAvailable(domain: String) -> Observable<Bool> {
    let params = ["domain": domain]
    let req: Observable<DomainAvailableResponse> = request(Route.domainAvailable(params: params))
    return req.map { $0.available }
  }

  public func getProductStock(productId: String, shopId: String) -> Observable<ProductStock> {
    return request(Route.getProductStock(productId: productId, shopId: shopId))
  }

  public func updateStock(productId: String, shopId: String, amount: Int) -> Observable<Void> {
    let params = ["value": amount]
    return request(Route.updateStock(productId: productId, shopId: shopId, params: params))
      .map { _ in return () }
  }

  public func update(shop: Shop) -> Observable<Void> {
    let apiUpdateShopRequest = APIUpdateShopRequest(shop: shop)

    guard let params = apiUpdateShopRequest.dictionary else {
      return .error(UploadServiceError.genericClientError)
    }

    return request(Route.updateShop(shopId: shop.id, params: params))
      .map { _ in return () }
  }

  public func getProductUrl(productId: String, shopId: String) -> Observable<ProductUrlResponse> {
    return request(Route.getProductUrl(productId: productId, shopId: shopId))
  }

  public func getShop(shopId: String) -> Observable<Shop> {
    return request(Route.getShop(shopId: shopId))
  }

  public func loginWithPaypal(params: [String: Any]) -> Observable<Session> {
    let req: Observable<PaypalLoginAuthResponse> = request(.loginWithPaypal(params: params))
    return req.map { Session(id: $0.session, user: $0.userId) }
  }

  public func assignUser(shopId id: String) -> Observable<Void> {
    return request(Route.assignUser(shopId: id))
      .map { _ in return () }
  }

  // MARK: - Request Factory

  private func request<M: Codable>(_ route: Route) -> Observable<M> {

    let properties = route.requestProperties

    guard let url = URL(string: properties.path, relativeTo: self.serverConfig.apiBaseUrl as URL) else {
      fatalError(
        "URL(string: \(properties.path), relativeToURL: \(self.serverConfig.apiBaseUrl)) == nil"
      )
    }

    let paramEncoding: ParameterEncoding
    if properties.method == .GET {
      paramEncoding = URLEncoding.default
    } else {
      paramEncoding = JSONEncoding.default
    }

    return SessionManager.default.rx
      .request(properties.method.alamofireMethod,
               url,
               parameters: properties.params,
               encoding: paramEncoding,
               headers: defaultHeaders)
      .map {
        #if DEBUG
        print($0.debugDescription)
        #endif

        return $0
      }
      .validate(statusCode: 200..<300)
      .responseJSON()
      .flatMap { (dataResponse: DataResponse) -> Observable<Data> in
        #if DEBUG
        print(dataResponse.debugDescription)
        #endif

        switch dataResponse.result {
        case let .success(value):
          return .just(try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted))
        case let .failure(error):
          return .error(error)
        }
      }
      .flatMap {
        Observable.just(try Service.decoder.decode(M.self, from: $0))
    }
  }

  private func request(_ route: Route) -> Observable<DataResponse<Any>> {
    let properties = route.requestProperties

    guard let url = URL(string: properties.path, relativeTo: self.serverConfig.apiBaseUrl as URL) else {
      fatalError(
        "URL(string: \(properties.path), relativeToURL: \(self.serverConfig.apiBaseUrl)) == nil"
      )
    }

    let paramEncoding: ParameterEncoding
    if properties.method == .GET {
      paramEncoding = URLEncoding.default
    } else {
      paramEncoding = JSONEncoding.default
    }

    return SessionManager.default.rx
      .request(properties.method.alamofireMethod,
               url,
               parameters: properties.params,
               encoding: paramEncoding,
               headers: defaultHeaders)
      .map {
        #if DEBUG
        print($0.debugDescription)
        #endif
        return $0
      }
      .validate(statusCode: 200..<300)
      .responseJSON()
      .map {
        #if DEBUG
        print($0.debugDescription)
        #endif
        return $0
    }
  }
}
