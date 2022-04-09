import Foundation

public func lerp(min: Double, max: Double, t: Double) -> Double {
  return (1 - t) * min + t * max
}
