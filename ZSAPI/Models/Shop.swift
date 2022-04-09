public struct Shop {
  public let id: String
  public let conf: Conf?
  public let domain: String

  public init(id: String, conf: Conf?, domain: String = "") {
    self.id = id
    self.conf = conf
    self.domain = domain
  }
}

extension Shop: Equatable {}
extension Shop: Codable {
  enum ShopKeys: String, CodingKey {
    case id
    case conf
    case domain
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ShopKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.conf = try container.decodeIfPresent(Conf.self, forKey: .conf)
    self.domain = try container.decodeIfPresent(String.self, forKey: .domain) ?? ""
  }
}
