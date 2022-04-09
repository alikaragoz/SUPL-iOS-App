import ZSAPI
import RxSwift

public class EditStock {
  public enum `Type`: String {
    case unmanaged
    case supl
  }

  public var type: Type
  public var amount: Int?
  public var needsUpdate: Bool

  public init(type: Type, amount: Int? = nil, needsUpdate: Bool = false) {
    self.type = type
    self.amount = amount
    self.needsUpdate = needsUpdate
  }
}

extension EditStock: Equatable {
  public static func == (lhs: EditStock, rhs: EditStock) -> Bool {
    return
      lhs.type == rhs.type &&
        lhs.amount == rhs.amount &&
        lhs.needsUpdate == rhs.needsUpdate
  }
}

// MARK: - Conversions

extension EditStock {
  public var stock: Stock? {
    switch self.type {
    case .unmanaged:
      return Stock(type: .unmanaged)
    case .supl:
      return Stock(type: .supl)
    }
  }
}

extension Stock {
  public var editStock: EditStock {
    switch self.type {
    case .unmanaged:
      return EditStock(type: .unmanaged)
    case .supl:
      return EditStock(type: .supl)
    }
  }
}
