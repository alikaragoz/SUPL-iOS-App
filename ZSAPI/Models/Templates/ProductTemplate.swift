// swiftlint:disable line_length
extension Product {
  public static let template = Product(
    id: "42",
    name: "DeadBeef",
    priceInfo: .template,
    shortDescription: "Lorem Ipsum is simply dummy.",
    description: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy.",
    visuals: [.template, .template, .template, .template])
}

extension ProductUrlResponse {
  internal static let template =
    ProductUrlResponse(url: URL(string: "https://api.supl.test/product_url")!)
}

extension ProductStock {
  internal static let template = ProductStock(value: 10)
}
