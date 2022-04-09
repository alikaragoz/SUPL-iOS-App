import ZSAPI
import ZSPrelude

public final class Analytics {
  private let clients: [TrackingClientType]
  private let bundle: NSBundleType
  private var paypalUser: PayPalUser?
  private var shop: Shop?

  public enum PreviewedProductContext {
    case create
    case cardMenu
    case homeProductCard

    var trackingString: String {
      switch self {
      case .create: return "create"
      case .cardMenu: return "card_menu"
      case .homeProductCard: return "home_product_card"
      }
    }
  }

  public enum OpenedShareProductContext {
    case cardMenu

    var trackingString: String {
      switch self {
      case .cardMenu: return "card_menu"
      }
    }
  }

  public enum OpenedCreateProductContext {
    case homeProductCard
    case homeEmptyState

    var trackingString: String {
      switch self {
      case .homeProductCard: return "home_product_card"
      case .homeEmptyState: return "home_empty_state"
      }
    }
  }

  public enum OpenedEditProductContext {
    case cardMenu

    var trackingString: String {
      switch self {
      case .cardMenu: return "card_menu"
      }
    }
  }

  private var userProperties: [String: Any] {
    var props: [String: Any] = [:]
    props["Build"] = self.bundle.infoDictionary?["CFBundleVersion"]
    props["Email"] = self.paypalUser?.email
    props["First Name"] = self.paypalUser?.firstName
    props["Last Name"] = self.paypalUser?.lastName
    props["Shop Name"] = self.shop?.conf?.companyInfo?.name
    props["Shop Domain"] = self.shop?.domain
    props["Product Count"] = self.shop?.conf?.products.count
    return props
  }

  // MARK: - Init

  public init(clients: [TrackingClientType], bundle: NSBundleType = Bundle.main) {
    self.clients = clients
    self.bundle = bundle
  }

  // MARK: - Identify

  public func set(userId: String) {
    self.clients.forEach { $0.setUserId(userId) }
  }

  // MARK: - User Properties

  public func set(paypalUser: PayPalUser) {
    self.paypalUser = paypalUser
    self.clients.forEach { $0.track(userProperties: self.userProperties) }
  }

  public func sessionId() -> String? {
    let sessionIds = self.clients.compactMap { $0.sessionId() }
    return sessionIds.first
  }

  public func deviceId() -> String? {
    let deviceIds = self.clients.compactMap { $0.deviceId() }
    return deviceIds.first
  }

  // MARK: - Other Properties

  public func set(shop: Shop) {
    self.shop = shop
    self.clients.forEach { $0.track(userProperties: self.userProperties) }
  }

  // MARK: - Events

  public func trackOpenedApp() {
    track(event: "Opened App")
    self.clients.forEach { $0.track(userProperties: self.userProperties) }
  }

  public func trackClosedApp() {
    track(event: "Closed App")
  }

  public func trackViewedHome() {
    track(event: "Viewed Home")
  }

  public func trackViewedCreateProductName() {
    track(event: "Viewed Create Product Name")
  }

  public func trackViewedCreateProductPrice() {
    track(event: "Viewed Create Product Price")
  }

  public func trackViewedCreateProductPictures() {
    track(event: "Viewed Create Product Pictures")
  }

  public func trackViewedCreateProductPaypal() {
    track(event: "Viewed Create Product Paypal")
  }

  public func trackViewedCreateProductSave() {
    track(event: "Viewed Create Product Save")
  }

  public func trackViewedCreateProductShare() {
    track(event: "Viewed Create Product Share")
  }

  public func trackViewedEditProductName() {
    track(event: "Viewed Edit Product Name")
  }

  public func trackViewedEditProductPrice() {
    track(event: "Viewed Edit Product Price")
  }

  public func trackViewedEditProductDescription() {
    track(event: "Viewed Edit Product Description")
  }

  public func trackViewedEditProductStock() {
    track(event: "Viewed Edit Product Stock")
  }

  public func trackViewedProductReview() {
    track(event: "Viewed Product Review")
  }

  public func trackViewedEditProduct() {
    track(event: "Viewed Edit Product")
  }

  public func trackViewedPaypalConnect() {
    track(event: "Viewed Paypal Connect")
  }

  public func trackViewedCurrencySelection() {
    track(event: "Viewed Currency Selection")
  }

  public func trackViewedShopEdition() {
    track(event: "Viewed Shop Edition")
  }

  public func trackViewedShopEditionName() {
    track(event: "Viewed Shop Edition Name")
  }

  public func trackViewedShopEditionDomain() {
    track(event: "Viewed Shop Edition Domain")
  }

  public func trackPreviewedProduct(context: PreviewedProductContext) {
    track(event: "Previewed Product", properties: ["from": context.trackingString])
  }

  public func trackOpenedShareProductDialog(context: OpenedShareProductContext) {
    track(event: "Opened Share Product Dialog", properties: ["from": context.trackingString])
  }

  public func trackCopiedLinkDuringCreation() {
    track(event: "Copied Link During Creation")
  }

  public func trackOpenedCreateProduct(context: OpenedCreateProductContext) {
    track(event: "Opened Create Product", properties: ["from": context.trackingString])
  }

  public func trackOpenedEditProduct(context: OpenedEditProductContext) {
    track(event: "Opened Edit Product", properties: ["from": context.trackingString])
  }

  public func trackOpenedPaypalConnect() {
    track(event: "Opened Paypal Connect")
  }

  public func trackSkippedShareDuringCreation() {
    track(event: "Skipped Share During Creation")
  }

  public func trackSkippedPaypalDuringCreation() {
    track(event: "Skipped Paypal During Creation")
  }

  public func trackSharedProduct(shareType: UIActivity.ActivityType?) {
    var properties: [String: String] = [:]
    properties["type"] = shareType.flatMap(shareTypeProperty)
    track(event: "Shared Product", properties: properties)
  }

  public func trackSucceededPaypalLogin() {
    track(event: "Succeeded PayPal Login")
  }

  public func trackErroredPaypalLogin(error: String) {
    track(event: "Errored PayPal Login", properties: ["error": error])
  }

  public func trackSucceededProductCreation(productUrlString: String) {
    track(event: "Succeeded Product Creation", properties: ["url": productUrlString])
  }

  public func trackErroredProductCreation(error: String) {
    track(event: "Errored Product Creation", properties: ["error": error])
  }

  public func trackSucceededProductEdition() {
    track(event: "Succeeded Product Edition")
  }

  public func trackErroredProductEdition(error: String) {
    track(event: "Errored Product Edition", properties: ["error": error])
  }

  public func trackSucceededProductDeletion() {
    track(event: "Succeeded Product Deletion")
  }

  public func trackErroredProductDeletion(error: String) {
    track(event: "Errored Product Deletion", properties: ["error": error])
  }

  public func trackSucceededShopEdition(shop: Shop) {
    var properties: [String: String] = [:]
    properties["domain"] = shop.domain
    properties["name"] = shop.conf?.companyInfo?.name
    properties["logo_url"] = shop.conf?.companyInfo?.logo?.url.absoluteString
    track(event: "Succeeded Shop Edition", properties: properties)
  }

  public func trackErroredShopEdition(shop: Shop, error: String) {
    var properties: [String: String] = [:]
    properties["domain"] = shop.domain
    properties["name"] = shop.conf?.companyInfo?.name
    properties["logo_url"] = shop.conf?.companyInfo?.logo?.url.absoluteString
    properties["error"] = error
    track(event: "Errored Shop Edition", properties: properties)
  }

  public func trackChangedCurrency(code: String) {
    track(event: "Changed Currency", properties: ["code": code])
  }

  public func trackCrashedApp() {
    self.track(event: "Crashed App")
  }

  public func trackOpenedIntercom() {
    self.track(event: "Opened Intercom")
  }

  public func trackPushPermissionOptIn() {
    self.track(event: "Confirmed Push Opt-In")
  }

  public func trackPushPermissionOptOut() {
    self.track(event: "Dismissed Push Opt-In")
  }

  private func track(event: String, properties: [String: Any]) {
    self.clients.forEach { $0.track(event: event, properties: properties) }
  }

  private func track(event: String) {
    self.clients.forEach { $0.track(event: event) }
  }
}

private func shareTypeProperty(_ shareType: UIActivity.ActivityType?) -> String? {
  guard let shareType = shareType else { return nil }

  switch shareType {
  case .postToFacebook:
    return "facebook"
  case .message:
    return "message"
  case .mail:
    return "email"
  case .copyToPasteboard:
    return "copy link"
  case .postToTwitter:
    return "twitter"
  default:
    return shareType.rawValue
  }
}
