// swiftlint:disable force_try
import Alamofire
import RxSwift

internal enum UploadRoute {
  case abort(url: URL)
  case complete(url: URL, params: [String: Any])
  case upload(url: URL, file: URL)

  internal var requestProperties:
    (method: Method, url: URL, params: [String: Any]?, file: URL?) {
    switch self {
    case let .abort(url):
      return (.POST, url, nil, nil)
    case let .complete(url, params):
      return (.POST, url, params, nil)
    case let .upload(url, file):
      return (.PUT, url, nil, file)
    }
  }
}

public protocol UploadServiceType {
  // aborts the file upload
  func abort(abortUrl: URL) -> Disposable

  // complete the file upload
  func complete(completeUrl: URL, parts: [FileUploadPart]) -> Observable<FileUploadCompleteResponse>

  // uploads a file
  func upload(uploadRequest: FileUploadRequest, file: URL) -> Observable<FileUploadCompleteResponse>

  // uploads a file part
  func uploadPart(part: FileUploadPart, file: URL) -> Observable<FileUploadPart>
}

public extension UploadServiceType {
  public static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}

public enum UploadServiceError: Error, LocalizedError {
  case genericClientError
  case noEtagInHeaders

  public var errorDescription: String? {
    switch self {
    case .genericClientError: return "genericClientError"
    case .noEtagInHeaders: return "noEtagInHeaders"
    }
  }
}

public struct UploadService: UploadServiceType {

  public init() {}

  private func abort(url: URL) -> Observable<DataRequest> {
    return request(UploadRoute.abort(url: url)).asObservable()
  }

  private func complete(url: URL, params: [String: Any]) -> Observable<DataRequest> {
    return request(UploadRoute.complete(url: url, params: params)).asObservable()
  }

  private func upload(url: URL, file: URL) -> Observable<UploadRequest> {
    return uploadRequest(UploadRoute.upload(url: url, file: file)).asObservable()
  }

  @discardableResult public func abort(abortUrl: URL) -> Disposable {
    return self.abort(url: abortUrl).subscribe()
  }

  public func complete(completeUrl: URL, parts: [FileUploadPart]) -> Observable<FileUploadCompleteResponse> {

    guard let params = FileUploadCompleteRequest(parts: parts).dictionary else {
      return .error(UploadServiceError.genericClientError)
    }

    return Observable.create { observer in
      _ = self.complete(url: completeUrl, params: params)
        .data()
        .flatMap {
          Observable.just(try UploadService.decoder.decode(FileUploadCompleteResponse.self, from: $0))
        }
        .do(onNext: {
          observer.on(.next($0))
          observer.on(.completed)
        })
        .do(onError: {
          observer.onError($0)
        })
        .subscribe()

      return Disposables.create()
    }
  }

  public func uploadPart(part: FileUploadPart, file: URL) -> Observable<FileUploadPart> {
    return Observable.create { observer in
      _ = self.upload(url: part.url, file: file)
        .do(onNext: {
          guard let etag = $0.response?.allHeaderFields["Etag"] as? String else {
            observer.onError(UploadServiceError.noEtagInHeaders)
            return
          }
          let newPart = FileUploadPart(index: part.index, url: part.url, etag: etag)
          observer.on(.next(newPart))
          observer.on(.completed)
        })
        .do(onError: {
          observer.onError($0)
        })
        .subscribe()

      return Disposables.create()
    }
  }

  public func upload(uploadRequest: FileUploadRequest, file: URL) -> Observable<FileUploadCompleteResponse> {
    return Observable.from(uploadRequest.uploadParts)
      .flatMap { self.uploadPart(part: $0, file: file) }
      .toArray()
      .flatMap { self.complete(completeUrl: uploadRequest.completeUrl, parts: $0) }
      .do(onError: { _ in
        self.abort(abortUrl: uploadRequest.abortUrl)
      })
  }

  // MARK: - Requests

  private func request(_ route: UploadRoute) -> Single<DataRequest> {
    let properties = route.requestProperties

    return SessionManager.default.rx
      .request(properties.method.alamofireMethod,
               properties.url,
               parameters: properties.params,
               encoding: JSONEncoding.default)
      .validate(statusCode: 200..<300)
      .asSingle()
  }

  private func uploadRequest(_ route: UploadRoute) -> Single<UploadRequest> {
    let properties = route.requestProperties

    guard let file = properties.file else {
      fatalError("File url needs to be set for the uploadRequest.")
    }

    let request = try! URLRequest.request(
      properties.method.alamofireMethod,
      properties.url,
      headers: ["Content-Type": "application/octet-stream"]
    )

    return SessionManager.default.rx
      .upload(file, urlRequest: request)
      .map { return $0.validate(statusCode: 200..<300) }
      .asSingle()
  }
}
