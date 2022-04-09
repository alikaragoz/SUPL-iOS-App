internal final class MockTrackingClient: TrackingClientType {

  internal var tracks: [(event: String, properties: [String: Any])] = []
  internal var userProperties: [String: Any] = [:]
  internal var userId: String?

  func track(event: String, properties: [String: Any]) {
    NSLog("[MockTrackingClient Track]: \(event), properties: \(properties)")
    self.tracks.append((event: event, properties: properties))
  }

  func track(userProperties: [String: Any]) {
    NSLog("[MockTrackingClient User Properties]: \(userProperties)")
    self.userProperties = userProperties
  }

  func setUserId(_ userId: String) {
    NSLog("[MockTrackingClient Setting User Id]: \(userId)")
    self.userId = userId
  }

  func sessionId() -> String? {
    NSLog("[MockTrackingClient Session Id]: mock_session")
    return "mock_session"
  }

  func deviceId() -> String? {
    NSLog("[MockTrackingClient Device Id]: mock_device")
    return "mock_device"
  }

  internal var events: [String] {
    return self.tracks.map { $0.event }
  }

  internal var properties: [[String: Any]] {
    return self.tracks.map { $0.properties }
  }

  internal func properties(forKey key: String) -> [String?] {
    return self.properties(forKey: key, as: String.self)
  }

  internal func properties <A> (forKey key: String, as klass: A.Type) -> [A?] {
    return self.tracks.map { $0.properties[key] as? A }
  }
}
