import Foundation

extension String {
  // Non-breaking space character.
  public static let nbsp = " "
  
  public func trimmed() -> String {
    return self.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
