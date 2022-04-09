extension Conf {
  internal static let template = Conf(
    companyInfo: .template,
    lang: "en",
    products: (0...10).map { _ in .template })
}
