// swiftlint:disable type_name
import ZSPrelude

extension Conf {
  public enum lens {
    public static let companyInfo = Lens<Conf, CompanyInfo?>(
      view: { $0.companyInfo },
      set: { Conf(companyInfo: $0, lang: $1.lang, products: $1.products) }
    )

    public static let lang = Lens<Conf, String?>(
      view: { $0.lang },
      set: { Conf(companyInfo: $1.companyInfo, lang: $0, products: $1.products) }
    )

    public static let products = Lens<Conf, [Product]>(
      view: { $0.products },
      set: { Conf(companyInfo: $1.companyInfo, lang: $1.lang, products: $0) }
    )
  }
}
