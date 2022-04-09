public extension Dictionary {

  // merges `self` with `other`, but all values from `other` trump the values in `self`
  public func withAllValuesFrom(_ other: Dictionary) -> Dictionary {
    var result = self
    other.forEach { result[$0] = $1 }
    return result
  }
}
