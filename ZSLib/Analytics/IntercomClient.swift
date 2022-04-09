import Intercom

public final class IntercomClient: TrackingClientType {

  public enum Env: String {
    case dev
    case prod
  }

  // MARK: - Init

  public init(env: Env) {
    switch env {
    case .dev:
      Intercom.setApiKey(Secrets.Intercom.Dev.apiKey, forAppId: Secrets.Intercom.Dev.appId)
    case .prod:
      Intercom.setApiKey(Secrets.Intercom.Prod.apiKey, forAppId: Secrets.Intercom.Prod.appId)
    }
  }

  // MARK: - TrackingClientType

  public func track(userProperties: [String: Any]) {
    #if DEBUG
    NSLog("[Intercom User Properties]: \(userProperties)")
    #endif
    let userAttr = ICMUserAttributes()
    userAttr.customAttributes = userProperties
    Intercom.updateUser(userAttr)
  }
  
  public func track(event: String, properties: [String: Any]) {
    #if DEBUG
    NSLog("[Intercom Track]: \(event), properties: \(properties)")
    #endif
    if properties.isEmpty {
      Intercom.logEvent(withName: event)
    } else {
      Intercom.logEvent(withName: event, metaData: properties)
    }
  }

  public func setUserId(_ userId: String) {}
  public func sessionId() -> String? { return nil }
  public func deviceId() -> String? { return nil }
}
