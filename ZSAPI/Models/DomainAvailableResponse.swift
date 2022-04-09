internal struct DomainAvailableResponse {
  internal var available: Bool

  internal init(available: Bool) {
    self.available = available
  }
}

extension DomainAvailableResponse: Equatable {}
extension DomainAvailableResponse: Codable {}
