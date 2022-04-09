// swiftlint:disable type_name
import ZSPrelude

extension FileUploadPart {
  public enum lens {
    public static let url = Lens<FileUploadPart, URL>(
      view: { $0.url },
      set: { FileUploadPart(index: $1.index, url: $0, etag: $1.etag) }
    )

    public static let etag = Lens<FileUploadPart, String?>(
      view: { $0.etag },
      set: { FileUploadPart(index: $1.index, url: $1.url, etag: $0) }
    )
  }
}
