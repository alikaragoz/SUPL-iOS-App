import ZSAPI

public struct Currency {
  public var name: String
  public var code: String
  public var symbol: String

  public init(name: String, code: String, symbol: String) {
    self.name = name
    self.code = code
    self.symbol = symbol
  }
}

extension Currency: Equatable {}

// MARK: - Helpers

extension Currency {

  public static func currencyFrom(locale: Locale) -> Currency {
    let code = locale.currencyCode ?? ""
    let name = locale.localizedString(forCurrencyCode: code) ?? ""
    let nslocale = NSLocale(localeIdentifier: code)
    let symbol = nslocale.displayName(forKey: NSLocale.Key.currencySymbol, value: code) ?? ""
    return Currency(name: name, code: code, symbol: symbol)
  }

  public static func currencyFrom(code: String, locale: Locale) -> Currency {
    let nslocale = NSLocale(localeIdentifier: code)
    let name = locale.localizedString(forCurrencyCode: code) ?? ""
    let symbol = nslocale.displayName(forKey: NSLocale.Key.currencySymbol, value: code) ?? ""
    return Currency(name: name, code: code, symbol: symbol)
  }

  public static func currenciesFrom(codes: [String], locale: Locale) -> [Currency] {
    return codes.map { Currency.currencyFrom(code: $0, locale: locale) }
  }

  public static func currencySymbolFrom(currencyCode code: String) -> String {
    let nslocale = NSLocale(localeIdentifier: code)
    let symbol = nslocale.displayName(forKey: NSLocale.Key.currencySymbol, value: code) ?? ""
    return symbol
  }
}
