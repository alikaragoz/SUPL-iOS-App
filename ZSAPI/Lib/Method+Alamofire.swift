import Alamofire

extension Method {
  var alamofireMethod: HTTPMethod {
    switch self {
    case .GET: return .get
    case .PATCH: return .patch
    case .POST: return .post
    case .PUT: return .put
    case .DELETE: return .delete
    }
  }
}
