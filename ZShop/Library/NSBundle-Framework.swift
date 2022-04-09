import Foundation

private class Pin {}

public extension Bundle {
  // returns an NSBundle pinned to the framework target. We could choose anything for the `forClass`
  // parameter as long as it is in the framework target.
  public static var framework: Bundle {
    return Bundle(for: Pin.self)
  }
}
