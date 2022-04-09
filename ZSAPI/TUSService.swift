// swiftlint:disable force_unwrapping
import RxSwift
import TUSKit
import Alamofire
import ZSPrelude

public struct TUSService {

  public enum TUSServiceError: Error, LocalizedError {
    case noLocationInHeaders

    public var errorDescription: String? {
      switch self {
      case .noLocationInHeaders: return "noLocationInHeaders"
      }
    }
  }

  private let tusSession: TUSSession
  private let endpoint =
    URL(string: "https://api.cloudflare.com/client/v4/zones/\(Secrets.Cloudflare.zoneId)/media")

  private let headers = [
    "X-Auth-Email": Secrets.Cloudflare.email,
    "X-Auth-Key": Secrets.Cloudflare.apiKey,
    "Tus-Resumable": "1.0.0"
  ]

  public init() {
    let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    let store = TUSFileUploadStore(url: dir!)
    tusSession = TUSSession(endpoint: endpoint!, dataStore: store!, allowsCellularAccess: true)
  }

  public func upload(file: URL) -> Observable<URL> {
    return self.create(file: file)
      .flatMap { self.initiateUpload(file: file, location: $0) }
  }

  public func create(file: URL) -> Observable<URL> {

    var fileLength = ""
    do {
      let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey])
      fileLength = "\(resourceValues.fileSize!)"
    } catch {
      return .error(error)
    }

    let augmentedHeaders = headers.withAllValuesFrom([
      "Content-Type": "application/json",
      "Upload-Metadata": "filename \(file.lastPathComponent)",
      "Upload-Length": fileLength
      ])

    return SessionManager.default.rx
      .request(.post, endpoint!, parameters: nil, encoding: JSONEncoding.default, headers: augmentedHeaders)
      .validate(statusCode: 200..<300)
      .responseData()
      .map { (dataResponse: DataResponse) -> URL in
        #if DEBUG
        print(dataResponse.debugDescription)
        #endif

        guard
          let location = dataResponse.response?.allHeaderFields["Location"] as? String,
          let url = URL(string: location) else {
            throw TUSServiceError.noLocationInHeaders
        }
        return url
      }
  }

  public func initiateUpload(file: URL, location: URL) -> Observable<URL> {
    return Observable.create { observer in
      let upload = self.tusSession.createUpload(fromFile: file,
                                                headers: self.headers,
                                                metadata: nil,
                                                uploadUrl: location)
      upload?.setChunkSize(5242880)
      upload?.resultBlock = { url in
        observer.on(.next(url))
      }

      upload?.failureBlock = { error in
        observer.on(.error(error))
      }

      upload?.progressBlock = { progress, total in
        print("\(progress)/\(total)")
      }

      upload?.resume()

      return Disposables.create {
        upload?.cancel()
      }
    }
  }

  public func videoDetails(url: URL) -> Observable<CloudFlareVideoDetails> {

    let augmentedHeaders = headers.withAllValuesFrom([
      "Content-Type": "application/json"
      ])

    return SessionManager.default.rx
      .request(.get, url, parameters: nil, encoding: JSONEncoding.default, headers: augmentedHeaders)
      .map {
        #if DEBUG
        print($0.debugDescription)
        #endif
        return $0
      }
      .validate(statusCode: 200..<300)
      .responseJSON()
      .flatMap { (dataResponse: DataResponse) -> Observable<Data> in
        #if DEBUG
        print(dataResponse.debugDescription)
        #endif

        switch dataResponse.result {
        case let .success(value):
          return .just(try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted))
        case let .failure(error):
          return .error(error)
        }
      }
      .flatMap {
        Observable.just(try Service.decoder.decode(CloudFlareVideoDetails.self, from: $0))
    }
  }
}
