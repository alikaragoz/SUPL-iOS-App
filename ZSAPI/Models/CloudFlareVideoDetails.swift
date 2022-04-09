public struct CloudFlareVideoDetails {
  public struct Result {
    public let uid: String
    public let thumbnail: URL?

    public init(uid: String, thumbnail: URL? = nil) {
      self.uid = uid
      self.thumbnail = thumbnail
    }
  }

  public let result: Result

  public init(result: Result) {
    self.result = result
  }
}

extension CloudFlareVideoDetails.Result: Equatable {}
extension CloudFlareVideoDetails.Result: Codable {}

extension CloudFlareVideoDetails: Equatable {}
extension CloudFlareVideoDetails: Codable {}

/*
{
  "result": {
    "uid": "0c9ef8cad13b880b53c502ef32232073",
    "thumbnail": "https://cloudflarestream.com/0c9ef8cad13b880b53c502ef32232073/thumbnails/thumb_5_0.png",
    "readyToStream": true,
    "status": {
      "state": "ready"
    },
    "meta": {
      "upload": "2~WG1a-X9bK9yvGw7nn08nFQEvcP7GK8w"
    },
    "labels": [],
    "created": "2019-02-14T10:03:31.964316Z",
    "modified": "2019-02-14T10:05:15.638668Z",
    "size": 9619010,
    "preview": "https://watch.cloudflarestream.com/0c9ef8cad13b880b53c502ef32232073",
    "allowedOrigins": [],
    "requireSignedURLs": false
  },
  "success": true,
  "errors": [],
  "messages": []
}
*/
