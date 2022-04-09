import ZSAPI

extension CompanyInfo {
  public var editCompanyInfo: EditCompanyInfo {

    var editPicture: EditPicture?
    if let logo = self.logo {
      editPicture = EditPicture(
        url: logo.url,
        width: logo.width,
        height: logo.height,
        color: logo.color,
        kind: logo.kind
      )
    }

    return EditCompanyInfo(name: self.name, editPicture: editPicture)
  }
}
