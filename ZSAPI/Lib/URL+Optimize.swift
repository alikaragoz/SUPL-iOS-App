extension URL {
  private struct Constants {
    struct OptimizerApi {
      static let scheme = "https"
      static let host = "fast.supl.co"
      static let path = "/v1/thumb"
    }
  }

  public func optimized(width: Int, height: Int? = nil) -> URL? {
    var components = URLComponents()
    let queryItemUrl = URLQueryItem(name: "url", value: self.absoluteString)
    let queryItemWidth = URLQueryItem(name: "width", value: String(width))
    let queryItemHeight = URLQueryItem(name: "height", value: String(height ?? width))

    components.scheme = Constants.OptimizerApi.scheme
    components.host = Constants.OptimizerApi.host
    components.path = Constants.OptimizerApi.path
    components.queryItems = [queryItemUrl, queryItemWidth, queryItemHeight]

    guard let url = try? components.asURL() else { return nil }
    return url
  }
}
