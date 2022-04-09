public class Visual: Codable {

  public enum Kind: String {
    case photo = "photo"
    case cloudflareVideo = "cloudflare_video"
  }

  public let width: Int?
  public let height: Int?
  public let color: String?
  public let kind: String
  public let url: URL
  public let thumbnail: Visual?

  public init(width: Int? = nil,
              height: Int? = nil,
              color: String? = nil,
              kind: String = Kind.photo.rawValue,
              url: URL,
              thumbnail: Visual? = nil) {
    self.width = width
    self.height = height
    self.color = color
    self.kind = kind
    self.url = url
    self.thumbnail = thumbnail
  }

  enum VisualKeys: String, CodingKey {
    case width
    case height
    case color
    case kind
    case url
    case thumbnail
  }

  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: VisualKeys.self)
    self.width = try container.decodeIfPresent(Int.self, forKey: .width)
    self.height = try container.decodeIfPresent(Int.self, forKey: .height)
    self.color = try container.decodeIfPresent(String.self, forKey: .color)
    self.kind = try container.decode(String.self, forKey: .kind)
    self.url = try container.decode(URL.self, forKey: .url)
    self.thumbnail = try container.decodeIfPresent(Visual.self, forKey: .thumbnail)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: VisualKeys.self)
    try container.encodeIfPresent(width, forKey: .width)
    try container.encodeIfPresent(height, forKey: .height)
    try container.encodeIfPresent(color, forKey: .color)
    try container.encode(kind, forKey: .kind)
    try container.encode(url, forKey: .url)
    try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
  }
}

extension Visual: Equatable {
  public static func == (lhs: Visual, rhs: Visual) -> Bool {
    return lhs.width == rhs.width &&
      lhs.height == rhs.height &&
      lhs.color == rhs.color &&
      lhs.kind == rhs.kind &&
      lhs.url == rhs.url &&
      lhs.thumbnail == rhs.thumbnail
  }
}
