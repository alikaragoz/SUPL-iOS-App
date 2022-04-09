extension FileUploadRequest {
  internal static let template = FileUploadRequest(
    uploadParts: [
      FileUploadPart(index: 1, url: URL(string: "https://api.supl.test")!, etag: nil),
      FileUploadPart(index: 2, url: URL(string: "https://api.supl.test")!, etag: nil),
      FileUploadPart(index: 3, url: URL(string: "https://api.supl.test")!, etag: nil)
    ],
    completeUrl: URL(string: "https://api.supl.test/complete")!,
    abortUrl: URL(string: "https://api.supl.test/abort")!)
}

extension FileUploadPart {
  internal struct Templates {
    public static let request = FileUploadPart(
      index: 1,
      url: URL(string: "https://api.supl.test")!,
      etag: nil)
    public static let response = FileUploadPart(
      index: 1,
      url: URL(string: "https://api.supl.test")!,
      etag: "deadbeaf")
  }
}

extension FileUploadCompleteResponse {
  internal static let template =
    FileUploadCompleteResponse(mediaUrl: URL(string: "https://api.supl.test/final_media_url")!)
}
