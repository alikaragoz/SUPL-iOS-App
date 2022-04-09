import Foundation
import ZSPrelude

public enum Format {
  public static func wholeNumber(_ x: Int, env: Environment = AppEnvironment.current) -> String {
    let formatter = NumberFormatterConfig.cachedFormatter(
      forConfig: .defaultWholeNumberConfig
        |> NumberFormatterConfig.lens.locale .~ env.locale
    )
    return formatter.string(for: x) ?? String(x)
  }

  public static func currency(_ amount: Double,
                              currencySymbol: String,
                              env: Environment = AppEnvironment.current) -> String {

    let formatter = NumberFormatterConfig.cachedFormatter(
      forConfig: .defaultCurrencyConfig
        |> NumberFormatterConfig.lens.locale .~ env.locale
        |> NumberFormatterConfig.lens.currencySymbol .~ currencySymbol
    )

    return formatter.string(for: amount)?
      .trimmed()
      .replacingOccurrences(of: String.nbsp + String.nbsp, with: String.nbsp)
      ?? (currencySymbol + String(amount))
  }
}

private struct NumberFormatterConfig: Hashable {
  fileprivate let numberStyle: NumberFormatter.Style
  fileprivate let roundingMode: NumberFormatter.RoundingMode
  fileprivate let maximumFractionDigits: Int
  fileprivate let generatesDecimalNumbers: Bool
  fileprivate let locale: Locale
  fileprivate let currencySymbol: String

  fileprivate func formatter() -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = self.numberStyle
    formatter.roundingMode = self.roundingMode
    formatter.maximumFractionDigits = self.maximumFractionDigits
    formatter.generatesDecimalNumbers = self.generatesDecimalNumbers
    formatter.locale = self.locale
    formatter.currencySymbol = self.currencySymbol
    return formatter
  }

  fileprivate static var formatters: [NumberFormatterConfig: NumberFormatter] = [:]

  fileprivate static let defaultWholeNumberConfig = NumberFormatterConfig(numberStyle: .decimal,
                                                                          roundingMode: .down,
                                                                          maximumFractionDigits: 0,
                                                                          generatesDecimalNumbers: false,
                                                                          locale: .current,
                                                                          currencySymbol: "€")

  fileprivate static let defaultCurrencyConfig = NumberFormatterConfig(numberStyle: .currency,
                                                                       roundingMode: .down,
                                                                       maximumFractionDigits: 2,
                                                                       generatesDecimalNumbers: false,
                                                                       locale: .current,
                                                                       currencySymbol: "€")

  fileprivate static func cachedFormatter(forConfig config: NumberFormatterConfig) -> NumberFormatter {
    let formatter = self.formatters[config] ?? config.formatter()
    self.formatters[config] = formatter
    return formatter
  }
}

// swiftlint:disable type_name
extension NumberFormatterConfig {
  fileprivate enum lens {
    fileprivate static let numberStyle = Lens<NumberFormatterConfig, NumberFormatter.Style>(
      view: { $0.numberStyle },
      set: { .init(numberStyle: $0,
                   roundingMode: $1.roundingMode,
                   maximumFractionDigits: $1.maximumFractionDigits,
                   generatesDecimalNumbers: $1.generatesDecimalNumbers,
                   locale: $1.locale,
                   currencySymbol: $1.currencySymbol) }
  )

    fileprivate static let roundingMode = Lens<NumberFormatterConfig, NumberFormatter.RoundingMode>(
      view: { $0.roundingMode },
      set: { .init(numberStyle: $1.numberStyle,
                   roundingMode: $0,
                   maximumFractionDigits: $1.maximumFractionDigits,
                   generatesDecimalNumbers: $1.generatesDecimalNumbers,
                   locale: $1.locale,
                   currencySymbol: $1.currencySymbol) }
    )

    fileprivate static let maximumFractionDigits = Lens<NumberFormatterConfig, Int>(
      view: { $0.maximumFractionDigits },
      set: { .init(numberStyle: $1.numberStyle,
                   roundingMode: $1.roundingMode,
                   maximumFractionDigits: $0,
                   generatesDecimalNumbers: $1.generatesDecimalNumbers,
                   locale: $1.locale,
                   currencySymbol: $1.currencySymbol) }
    )

    fileprivate static let generatesDecimalNumbers = Lens<NumberFormatterConfig, Bool>(
      view: { $0.generatesDecimalNumbers },
      set: { .init(numberStyle: $1.numberStyle,
                   roundingMode: $1.roundingMode,
                   maximumFractionDigits: $1.maximumFractionDigits,
                   generatesDecimalNumbers: $0,
                   locale: $1.locale,
                   currencySymbol: $1.currencySymbol) }
    )

    fileprivate static let locale = Lens<NumberFormatterConfig, Locale>(
      view: { $0.locale },
      set: { .init(numberStyle: $1.numberStyle,
                   roundingMode: $1.roundingMode,
                   maximumFractionDigits: $1.maximumFractionDigits,
                   generatesDecimalNumbers: $1.generatesDecimalNumbers,
                   locale: $0,
                   currencySymbol: $1.currencySymbol) }
    )

    fileprivate static let currencySymbol = Lens<NumberFormatterConfig, String>(
      view: { $0.currencySymbol },
      set: { .init(numberStyle: $1.numberStyle,
                   roundingMode: $1.roundingMode,
                   maximumFractionDigits: $1.maximumFractionDigits,
                   generatesDecimalNumbers: $1.generatesDecimalNumbers,
                   locale: $1.locale,
                   currencySymbol: $0) }
    )
  }
}
// swiftlint:enable type_name
