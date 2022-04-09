import RxSwift

internal struct MockUploadService: UploadServiceType {
  
  private let uploadPartResponse: FileUploadPart?
  private let uploadPartError: Error?
  
  private let completeResponse: FileUploadCompleteResponse?
  private let completeError: Error?
  
  private let uploadResponse: FileUploadCompleteResponse?
  private let uploadError: Error?
  
  public init(uploadPartResponse: FileUploadPart? = nil,
              uploadPartError: Error? = nil,
              completeResponse: FileUploadCompleteResponse? = nil,
              completeError: Error? = nil,
              uploadResponse: FileUploadCompleteResponse? = nil,
              uploadError: Error? = nil) {
    
    self.uploadPartResponse = uploadPartResponse
    self.uploadPartError = uploadPartError
    
    self.completeResponse = completeResponse
    self.completeError = completeError
    
    self.uploadResponse = uploadResponse
    self.uploadError = uploadError
  }
  
  func abort(abortUrl: URL) -> Disposable {
    return Disposables.create()
  }
  
  func complete(completeUrl: URL, parts: [FileUploadPart]) -> Observable<FileUploadCompleteResponse> {
    if let error = completeError {
      return .error(error)
    }
    return .just(completeResponse ?? .template)
  }
  
  func upload(uploadRequest: FileUploadRequest, file: URL) -> Observable<FileUploadCompleteResponse> {
    if let error = uploadError {
      return .error(error)
    }
    return .just(uploadResponse ?? .template)
  }
  
  func uploadPart(part: FileUploadPart, file: URL) -> Observable<FileUploadPart> {
    if let error = uploadPartError {
      return .error(error)
    }
    return .just(uploadPartResponse ?? FileUploadPart.Templates.response)
  }
}
