import ZSAPI

extension EditPicture {
  public var visual: Visual? {
    return Visual(
      width: width,
      height: height,
      color: self.color,
      kind: self.kind,
      url: self.url,
      thumbnail: self.thumbnail?.visual
    )
  }
}
