import Amplitude

public final class AmplitudeClient: TrackingClientType {

  private let amplitude: Amplitude?

  public enum Env: String {
    case dev
    case prod
  }

  // MARK: - Init
  
  public init(env: Env) {
    self.amplitude = AmplitudeClient.amplitudeClientConfiguredWith(env: env)
  }

  internal static func amplitudeClientConfiguredWith(env: Env) -> Amplitude? {
    let conf: (name: String, apiKey: String)

    switch env {
    case .dev:
      conf = (Env.dev.rawValue, Secrets.Amplitude.Dev.apiKey)
    case .prod:
      conf = (Env.prod.rawValue, Secrets.Amplitude.Prod.apiKey)
    }

    let amplitude = Amplitude.instance(withName: conf.name)
    amplitude?.trackingSessionEvents = false
    amplitude?.initializeApiKey(conf.apiKey)
    return amplitude
  }

  // MARK: - TrackingClientType

  public func track(userProperties: [String: Any]) {
    #if DEBUG
    NSLog("[Amplitude User Properties]: \(userProperties)")
    #endif
    amplitude?.setUserProperties(userProperties)
  }
  
  public func track(event: String, properties: [String: Any]) {
    #if DEBUG
    NSLog("[Amplitude Track]: \(event), properties: \(properties)")
    #endif
    amplitude?.logEvent(event, withEventProperties: properties)
  }

  public func setUserId(_ userId: String) {
    #if DEBUG
    NSLog("[Amplitude Track]: Setting User Id: \(userId)")
    #endif
    amplitude?.setUserId(userId)
  }

  public func sessionId() -> String? {
    guard let sessionId = amplitude?.getSessionId() else { return nil }

    #if DEBUG
    NSLog("[Amplitude Session Id]: \(sessionId)")
    #endif
    return String(sessionId)
  }

  public func deviceId() -> String? {
    guard let deviceId = amplitude?.getDeviceId() else { return nil }

    #if DEBUG
    NSLog("[Amplitude Device Id]: \(deviceId)")
    #endif
    return deviceId
  }
}
