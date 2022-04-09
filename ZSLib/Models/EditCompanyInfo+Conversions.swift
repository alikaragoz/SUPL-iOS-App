import ZSAPI

extension EditCompanyInfo {
  public var companyInfo: CompanyInfo {
    return CompanyInfo(name: self.name, logo: self.editPicture?.visual)
  }
}
