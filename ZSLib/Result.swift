import Foundation

public enum Result<Value> {
  case success(Value)
  case failure(Error)
}

extension Result {
  func resolve() throws -> Value {
    switch self {
    case .success(let value): return value
    case .failure(let error): throw error
    }
  }
}

extension Result where Value == Data {
  func decoded<T: Decodable>() throws -> T {
    let decoder = JSONDecoder()
    let data = try resolve()
    return try decoder.decode(T.self, from: data)
  }
}
