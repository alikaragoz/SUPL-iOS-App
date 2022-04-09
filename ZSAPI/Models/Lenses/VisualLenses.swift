// swiftlint:disable type_name
import ZSPrelude

extension Visual {
  public enum lens {
    public static let width = Lens<Visual, Int?>(
      view: { $0.width },
      set: { Visual(width: $0, height: $1.height, color: $1.color, kind: $1.kind, url: $1.url) }
    )

    public static let height = Lens<Visual, Int?>(
      view: { $0.height },
      set: { Visual(width: $1.width, height: $0, color: $1.color, kind: $1.kind, url: $1.url) }
    )

    public static let color = Lens<Visual, String?>(
      view: { $0.color },
      set: { Visual(width: $1.width, height: $1.height, color: $0, kind: $1.kind, url: $1.url) }
    )

    public static let kind = Lens<Visual, String>(
      view: { $0.kind },
      set: { Visual(width: $1.width, height: $1.height, color: $1.color, kind: $0, url: $1.url) }
    )

    public static let url = Lens<Visual, URL>(
      view: { $0.url },
      set: { Visual(width: $1.width, height: $1.height, color: $1.color, kind: $1.kind, url: $0) }
    )
  }
}
