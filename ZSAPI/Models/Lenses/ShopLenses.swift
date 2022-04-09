// swiftlint:disable type_name
import ZSPrelude

extension Shop {
  public enum lens {
    public static let conf = Lens<Shop, Conf?>(
      view: { $0.conf },
      set: { Shop(id: $1.id, conf: $0, domain: $1.domain) }
    )

    public static let domain = Lens<Shop, String>(
      view: { $0.domain },
      set: { Shop(id: $1.id, conf: $1.conf, domain: $0) }
    )
  }
}
