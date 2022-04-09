extension Locale {
  func isCurrenySymbolAtStart() -> Bool {
    let currencyFormatter = NumberFormatter()
    currencyFormatter.numberStyle = .currency
    currencyFormatter.locale = self
    let positiveFormat = currencyFormatter.positiveFormat as NSString
    let currencySymbolLocation = positiveFormat.range(of: "¤").location
    return (currencySymbolLocation == 0)
  }
}
