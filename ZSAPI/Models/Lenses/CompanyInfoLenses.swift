// swiftlint:disable type_name
import ZSPrelude

extension CompanyInfo {
  public enum lens {
    public static let name = Lens<CompanyInfo, String?>(
      view: { $0.name },
      set: { CompanyInfo(name: $0, logo: $1.logo) }
    )

    public static let logo = Lens<CompanyInfo, Visual?>(
      view: { $0.logo },
      set: { CompanyInfo(name: $1.name, logo: $0) }
    )
  }
}
