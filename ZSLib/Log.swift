public func log(_ message: String? = nil, file: String = #file, function: String = #function) {
  print("[\(file) -> \(function)]: \(message ?? ".")")
}
