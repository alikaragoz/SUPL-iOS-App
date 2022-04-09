public struct PaypalCredentials {
  public let live: PaypalClient
  public let sandbox: PaypalClient
  public let user: PayPalUser
}

extension PaypalCredentials: Equatable {}
extension PaypalCredentials: Codable {}

public struct PaypalClient {
  public let id: String
  public let secret: String

  enum CodingKeys: String, CodingKey {
    case id = "client_id"
    case secret = "client_secret"
  }
}

extension PaypalClient: Equatable {}
extension PaypalClient: Codable {}

public struct PayPalUser {

  public let email: String
  public let firstName: String
  public let lastName: String

  enum CodingKeys: String, CodingKey {
    case email
    case firstName = "first_name"
    case lastName = "last_name"
  }
}

extension PayPalUser: Equatable {}
extension PayPalUser: Codable {}
