import Alamofire
import Foundation
import RxSwift

public let AlamofireUnknownError = NSError(domain: "AlamofireDomain", code: -1, userInfo: nil)

// MARK: - URLRequest

extension URLRequest {
  public static func request(_ method: Alamofire.HTTPMethod,
                             _ url: URLConvertible,
                             parameters: [String: Any]? = nil,
                             encoding: ParameterEncoding = URLEncoding.default,
                             headers: [String: String]? = nil) throws -> Foundation.URLRequest {
    var mutableURLRequest = URLRequest(url: try url.asURL())
    mutableURLRequest.httpMethod = method.rawValue

    if let headers = headers {
      for (headerField, headerValue) in headers {
        mutableURLRequest.setValue(headerValue, forHTTPHeaderField: headerField)
      }
    }

    if let parameters = parameters {
      mutableURLRequest = try encoding.encode(mutableURLRequest, with: parameters)
    }

    return mutableURLRequest
  }
}

// MARK: - RxAlamofireRequest & RxAlamofireResponse

protocol RxAlamofireRequest {
  func responseWith(completionHandler: @escaping (RxAlamofireResponse) -> Void)
  func resume()
  func cancel()
}

protocol RxAlamofireResponse {
  var error: Error? { get }
}

extension DataRequest: RxAlamofireRequest {
  func responseWith(completionHandler: @escaping (RxAlamofireResponse) -> Void) {
    response { (response) in
      completionHandler(response)
    }
  }
}

extension DefaultDataResponse: RxAlamofireResponse {}

// MARK: - SessionManager

extension SessionManager: ReactiveCompatible {}

extension Reactive where Base: SessionManager {

  func request<R: RxAlamofireRequest>(
    _ createRequest: @escaping (SessionManager) throws -> R) -> Observable<R> {
    return Observable.create { observer -> Disposable in
      let request: R
      do {
        request = try createRequest(self.base)
        observer.on(.next(request))
        request.responseWith(completionHandler: { (response) in
          if let error = response.error {
            observer.on(.error(error))
          } else {
            observer.on(.completed)
          }
        })

        if !self.base.startRequestsImmediately {
          request.resume()
        }

        return Disposables.create {
          request.cancel()
        }
      } catch let error {
        observer.on(.error(error))
        return Disposables.create()
      }
    }
  }

  public func request(_ method: Alamofire.HTTPMethod,
                      _ url: URLConvertible,
                      parameters: [String: Any]? = nil,
                      encoding: ParameterEncoding = URLEncoding.default,
                      headers: [String: String]? = nil) -> Observable<DataRequest> {
    return request { manager in
      return manager.request(
        url,
        method: method,
        parameters: parameters,
        encoding: encoding,
        headers: headers
      )
    }
  }

  public func upload(_ file: URL, urlRequest: URLRequestConvertible) -> Observable<UploadRequest> {
    return request { manager in
      return manager.upload(file, with: urlRequest)
    }
  }
}

// MARK: - DataRequest

extension DataRequest: ReactiveCompatible {}

extension Reactive where Base: DataRequest {
  func validateSuccessfulResponse() -> DataRequest {
    return self.base.validate(statusCode: 200 ..< 300)
  }

  public func result<T: DataResponseSerializerProtocol>(
    queue: DispatchQueue? = nil,
    responseSerializer: T)
    -> Observable<T.SerializedObject> {
      return Observable.create { observer in
        let dataRequest = self.validateSuccessfulResponse()
          .response(queue: queue, responseSerializer: responseSerializer) { (packedResponse) -> Void in
            switch packedResponse.result {
            case .success(let result):
              if packedResponse.response != nil {
                observer.on(.next(result))
                observer.on(.completed)
              } else {
                observer.on(.error(AlamofireUnknownError))
              }
            case .failure(let error):
              observer.on(.error(error as Error))
            }
        }
        return Disposables.create {
          dataRequest.cancel()
        }
      }
  }

  public func responseJSON() -> Observable<DataResponse<Any>> {
    return Observable.create { observer in
      let request = self.base

      request.responseJSON { response in
        if let error = response.result.error {
          observer.on(.error(error))
        } else {
          observer.on(.next(response))
          observer.on(.completed)
        }
      }
      
      return Disposables.create {
        request.cancel()
      }
    }
  }

  public func responseData() -> Observable<DataResponse<Data>> {
    return Observable.create { observer in
      let request = self.base

      request.responseData { response in
        if let error = response.result.error {
          observer.on(.error(error))
        } else {
          observer.on(.next(response))
          observer.on(.completed)
        }
      }

      return Disposables.create {
        request.cancel()
      }
    }
  }

  public func data() -> Observable<Data> {
    return result(responseSerializer: DataRequest.dataResponseSerializer())
  }

  public func string(encoding: String.Encoding? = nil) -> Observable<String> {
    return result(responseSerializer: Base.stringResponseSerializer(encoding: encoding))
  }
}

extension ObservableType where E == DataRequest {
  public func responseJSON() -> Observable<DataResponse<Any>> {
    return flatMap { $0.rx.responseJSON() }
  }

  public func responseData() -> Observable<DataResponse<Data>> {
    return flatMap { $0.rx.responseData() }
  }

  public func data() -> Observable<Data> {
    return flatMap { $0.rx.data() }
  }

  public func validate<S: Sequence>(statusCode: S) -> Observable<E> where S.Element == Int {
    return map { $0.validate(statusCode: statusCode) }
  }

  public func string(encoding: String.Encoding? = nil) -> Observable<String> {
    return flatMap { $0.rx.string(encoding: encoding) }
  }

  public func progress() -> Observable<RxProgress> {
    return flatMap { $0.rx.progress() }
  }
}

extension Reactive where Base: Request {
  public func progress() -> Observable<RxProgress> {
    return Observable.create { observer in
      let handler: Request.ProgressHandler = { progress in
        let rxProgress = RxProgress(bytesWritten: progress.completedUnitCount,
                                    totalBytes: progress.totalUnitCount)
        observer.on(.next(rxProgress))

        if rxProgress.bytesWritten >= rxProgress.totalBytes {
          observer.on(.completed)
        }
      }

      if let uploadReq = self.base as? UploadRequest {
        uploadReq.uploadProgress(closure: handler)
      } else if let downloadReq = self.base as? DownloadRequest {
        downloadReq.downloadProgress(closure: handler)
      } else if let dataReq = self.base as? DataRequest {
        dataReq.downloadProgress(closure: handler)
      }

      return Disposables.create()
      }

      .startWith(RxProgress(bytesWritten: 0, totalBytes: 0))
  }
}

// MARK: RxProgress
public struct RxProgress {
  public let bytesWritten: Int64
  public let totalBytes: Int64

  public init(bytesWritten: Int64, totalBytes: Int64) {
    self.bytesWritten = bytesWritten
    self.totalBytes = totalBytes
  }
}

extension RxProgress {
  public var bytesRemaining: Int64 {
    return totalBytes - bytesWritten
  }

  public var completed: Float {
    if totalBytes > 0 {
      return Float(bytesWritten) / Float(totalBytes)
    } else {
      return 0
    }
  }
}

extension RxProgress: Equatable {}

public func == (lhs: RxProgress, rhs: RxProgress) -> Bool {
  return lhs.bytesWritten == rhs.bytesWritten &&
    lhs.totalBytes == rhs.totalBytes
}
