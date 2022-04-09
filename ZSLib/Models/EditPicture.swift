import ZSAPI
import RxSwift

public class EditPicture {
  public var url: URL
  public var width: Int?
  public var height: Int?
  public var color: String?
  public var kind: String
  public var thumbnail: EditPicture?
  public var process: Observable<EditPicture>?
  public var disposable: Disposable?

  public init(
    url: URL,
    width: Int? = nil,
    height: Int? = nil,
    color: String? = nil,
    kind: String = Visual.Kind.photo.rawValue,
    thumbnail: EditPicture? = nil,
    process: Observable<EditPicture>? = nil) {
    self.url = url
    self.width = width
    self.height = height
    self.color = color
    self.kind = kind
    self.thumbnail = thumbnail
    self.process = process
  }
}

extension EditPicture: Equatable {
  public static func == (lhs: EditPicture, rhs: EditPicture) -> Bool {
    return lhs.url == rhs.url &&
      lhs.width == rhs.width &&
      lhs.height == rhs.height &&
      lhs.color == rhs.color &&
      lhs.kind == rhs.kind &&
      lhs.thumbnail == rhs.thumbnail
  }
}
