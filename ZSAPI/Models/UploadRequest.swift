public struct FileUploadPart {
  public let index: Int
  public let url: URL
  public let etag: String?

  public init(index: Int, url: URL, etag: String?) {
    self.index = index
    self.url = url
    self.etag = etag
  }
}

extension FileUploadPart: Equatable {}
extension FileUploadPart: Codable {}

public struct FileUploadRequest {
  public let uploadParts: [FileUploadPart]
  public let completeUrl: URL
  public let abortUrl: URL

  public init(uploadParts: [FileUploadPart],
              completeUrl: URL,
              abortUrl: URL) {
    self.uploadParts = uploadParts
    self.completeUrl = completeUrl
    self.abortUrl = abortUrl
  }
}

extension FileUploadRequest: Equatable {}
extension FileUploadRequest: Codable {}

public struct FileUploadCompleteRequest {
  public let parts: [FileUploadPart]

  public init(parts: [FileUploadPart]) {
    self.parts = parts
  }
}

extension FileUploadCompleteRequest: Equatable {}
extension FileUploadCompleteRequest: Codable {}

public struct FileUploadCompleteResponse {
  public let mediaUrl: URL

  public init(mediaUrl: URL) {
    self.mediaUrl = mediaUrl
  }
}

extension FileUploadCompleteResponse: Equatable {}
extension FileUploadCompleteResponse: Codable {}
