import UIKit

public enum Nib: String {
  case TheNib
}

protocol NibLoading {
  associatedtype CustomNibType

  static func fromNib(nib: Nib) -> CustomNibType?
}

extension NibLoading {
  static func fromNib(nib: Nib) -> Self? {
    guard let view = UINib(nibName: nib.rawValue, bundle: .framework)
      .instantiate(withOwner: self, options: nil)
      .first as? Self else {
        assertionFailure("Nib not found")
        return nil
    }

    return view
  }
}
