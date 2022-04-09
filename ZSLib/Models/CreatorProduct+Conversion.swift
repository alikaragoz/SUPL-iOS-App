import ZSAPI

extension CreatorProduct {
  public var editProduct: EditProduct {

    let pictures = self.medias?.map {
      EditPicture(
        url: $0.url,
        kind: $0.isImage ? Visual.Kind.photo.rawValue : Visual.Kind.cloudflareVideo.rawValue
      )
    }

    return EditProduct(
      name: self.name,
      priceInfo: self.priceInfo,
      pictures: pictures
    )
  }
}
