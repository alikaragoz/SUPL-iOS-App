public protocol TrackingClientType {
  func track(userProperties: [String: Any])
  func track(event: String, properties: [String: Any])
  func setUserId(_ userId: String)
  func sessionId() -> String?
  func deviceId() -> String?
}

public extension TrackingClientType {
  public func track(event: String) {
    self.track(event: event, properties: [:])
  }
}
