// swiftlint:disable type_name
import Alamofire
import RxSwift
import ZSPrelude

internal struct MockService: ServiceType {
  internal let appId: String
  internal let buildVersion: String
  internal let language: String
  internal let serverConfig: ServerConfigType
  internal let session: SessionType?

  private let createShopResponse: Shop?
  private let createShopError: Error?

  private let createMediaResponse: FileUploadRequest?
  private let createMediaError: Error?

  private let domainAvailableResponse: Bool?
  private let domainAvailableError: Error?

  private let updateShopError: Error?

  private let getProductUrlResponse: ProductUrlResponse?
  private let getProductUrlError: Error?

  private let getShopResponse: Shop?
  private let getShopError: Error?

  private let loginWithPaypalResponse: Session?
  private let loginWithPaypalError: Error?

  private let getProductStockResponse: ProductStock?
  private let getProductStockError: Error?

  private let updateStockError: Error?

  private let assignUserError: Error?

  internal init(appId: String,
                buildVersion: String,
                language: String,
                serverConfig: ServerConfigType,
                session: SessionType?) {

    self.init(appId: appId,
              buildVersion: buildVersion,
              language: language,
              serverConfig: serverConfig,
              session: session,
              createShopResponse: nil)
  }

  internal init(appId: String = "com.supl.mock",
                buildVersion: String = "1",
                language: String = "en",
                serverConfig: ServerConfigType = ServerConfig.production,
                session: SessionType? = nil,
                createShopResponse: Shop? = nil,
                createShopError: Error? = nil,
                createMediaResponse: FileUploadRequest? = nil,
                createMediaError: Error? = nil,
                domainAvailableResponse: Bool? = nil,
                domainAvailableError: Error? = nil,
                updateShopError: Error? = nil,
                getProductUrlResponse: ProductUrlResponse? = nil,
                getProductUrlError: Error? = nil,
                getShopResponse: Shop? = nil,
                getShopError: Error? = nil,
                loginWithPaypalResponse: Session? = nil,
                loginWithPaypalError: Error? = nil,
                getProductStockResponse: ProductStock? = nil,
                getProductStockError: Error? = nil,
                updateStockError: Error? = nil,
                assignUserError: Error? = nil) {
    self.appId = appId
    self.buildVersion = buildVersion
    self.language = language
    self.serverConfig = serverConfig
    self.session = session

    self.createShopResponse = createShopResponse
    self.createShopError = createShopError
    self.createMediaResponse = createMediaResponse
    self.createMediaError = createMediaError
    self.domainAvailableResponse = domainAvailableResponse
    self.domainAvailableError = domainAvailableError
    self.updateShopError = updateShopError
    self.getProductUrlResponse = getProductUrlResponse
    self.getProductUrlError = getProductUrlError
    self.getShopResponse = getShopResponse
    self.getShopError = getShopError
    self.loginWithPaypalResponse = loginWithPaypalResponse
    self.loginWithPaypalError = loginWithPaypalError
    self.getProductStockResponse = getProductStockResponse
    self.getProductStockError = getProductStockError
    self.updateStockError = updateStockError
    self.assignUserError = assignUserError
  }

  func login(_ session: SessionType) -> MockService {
    return self |> MockService.lens.session .~ session
  }

  func logout() -> MockService {
    return self |> MockService.lens.session .~ session
  }

  func createShop() -> Observable<Shop> {
    if let error = createShopError {
      return .error(error)
    }
    return .just(createShopResponse ?? Shop.Templates.fromApiService)
  }

  func createMedia(shopId id: String, mediaType type: MediaType) -> Observable<FileUploadRequest> {
    if let error = createMediaError {
      return .error(error)
    }
    return .just(createMediaResponse ?? .template)
  }

  func domainAvailable(domain: String) -> Observable<Bool> {
    if let error = domainAvailableError {
      return .error(error)
    }
    return .just(domainAvailableResponse ?? true)
  }

  func update(shop: Shop) -> Observable<Void> {
    if let error = updateShopError {
      return .error(error)
    }
    return .just(())
  }

  func getProductUrl(productId: String, shopId: String) -> Observable<ProductUrlResponse> {
    if let error = getProductUrlError {
      return .error(error)
    }
    return .just(getProductUrlResponse ?? .template)
  }

  func getShop(shopId: String) -> Observable<Shop> {
    if let error = getShopError {
      return .error(error)
    }
    return .just(getShopResponse ?? Shop.Templates.fromApiService)
  }

  func loginWithPaypal(params: [String: Any]) -> Observable<Session> {
    if let error = loginWithPaypalError {
      return .error(error)
    }
    return .just(loginWithPaypalResponse ?? .template)
  }

  func assignUser(shopId id: String) -> Observable<Void> {
    if let error = assignUserError {
      return .error(error)
    }
    return .just(())
  }

  func getProductStock(productId: String, shopId: String) -> Observable<ProductStock> {
    if let error = getProductUrlError {
      return .error(error)
    }
    return .just(getProductStockResponse ?? .template)
  }

  func updateStock(productId: String, shopId: String, amount: Int) -> Observable<Void> {
    if let error = updateStockError {
      return .error(error)
    }
    return .just(())
  }
}

private extension MockService {
  enum lens {
    static let session = Lens<MockService, SessionType?>(
      view: { $0.session },
      set: {
        MockService(
          appId: $1.appId,
          buildVersion: $1.buildVersion,
          language: $1.language,
          serverConfig: $1.serverConfig,
          session: $0,
          createShopResponse: $1.createShopResponse,
          createShopError: $1.createShopError,
          createMediaResponse: $1.createMediaResponse,
          createMediaError: $1.createMediaError,
          updateShopError: $1.updateShopError,
          getProductUrlResponse: $1.getProductUrlResponse,
          getProductUrlError: $1.getProductUrlError
        )
    }
    )
  }
}
