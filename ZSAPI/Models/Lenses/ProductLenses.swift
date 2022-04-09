// swiftlint:disable type_name
import ZSPrelude

extension Product {
  public enum lens {
    public static let id = Lens<Product, String>(
      view: { $0.id },
      set: { Product(
        id: $0,
        name: $1.name,
        priceInfo: $1.priceInfo,
        shortDescription: $1.shortDescription,
        description: $1.description,
        visuals: $1.visuals) }
    )

    public static let name = Lens<Product, String>(
      view: { $0.name },
      set: { Product(
        id: $1.id,
        name: $0,
        priceInfo: $1.priceInfo,
        shortDescription: $1.shortDescription,
        description: $1.description,
        visuals: $1.visuals) }
    )

    public static let priceInfo = Lens<Product, PriceInfo>(
      view: { $0.priceInfo },
      set: { Product(
        id: $1.id,
        name: $1.name,
        priceInfo: $0,
        shortDescription: $1.shortDescription,
        description: $1.description,
        visuals: $1.visuals) }
    )

    public static let shortDescription = Lens<Product, String?>(
      view: { $0.shortDescription },
      set: { Product(
        id: $1.id,
        name: $1.name,
        priceInfo: $1.priceInfo,
        shortDescription: $0,
        description: $1.description,
        visuals: $1.visuals) }
    )

    public static let description = Lens<Product, String?>(
      view: { $0.description },
      set: { Product(
        id: $1.id,
        name: $1.name,
        priceInfo: $1.priceInfo,
        shortDescription: $1.shortDescription,
        description: $0,
        visuals: $1.visuals) }
    )

    public static let visuals = Lens<Product, [Visual]>(
      view: { $0.visuals },
      set: { Product(
        id: $1.id,
        name: $1.name,
        priceInfo: $1.priceInfo,
        shortDescription: $1.shortDescription,
        description: $1.description,
        visuals: $0) }
    )
  }
}
