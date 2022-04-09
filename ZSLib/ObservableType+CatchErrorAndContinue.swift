import Foundation
import RxSwift

extension ObservableType {
  public func catchErrorAndContinue(handler: @escaping (Error) throws -> Void) -> RxSwift.Observable<Self.E> {
    return self
      .catchError { error in
        try handler(error)
        return Observable.error(error)
      }
      .retry()
  }
}
