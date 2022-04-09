private let encoder: JSONEncoder = {
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  return encoder
}()

public extension Encodable {
  // a `Codable` object encoded to a json dictionary.
  public var dictionary: [String: Any]? {
    guard let data = try? encoder.encode(self) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments))
      .flatMap { $0 as? [String: Any] }
  }
}
