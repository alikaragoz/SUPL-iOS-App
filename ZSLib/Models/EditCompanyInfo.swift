import ZSAPI

public struct EditCompanyInfo {
  public var name: String?
  public var editPicture: EditPicture?

  public init(name: String? = nil, editPicture: EditPicture? = nil) {
    self.name = name
    self.editPicture = editPicture
  }
}

extension EditCompanyInfo: Equatable {}
