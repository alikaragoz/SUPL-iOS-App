import ZSAPI

extension Visual {
  public var editPicture: EditPicture {
    return EditPicture(
      url: self.url,
      width: self.width,
      height: self.height,
      color: self.color,
      kind: self.kind,
      thumbnail: self.thumbnail?.editPicture
    )
  }
}
