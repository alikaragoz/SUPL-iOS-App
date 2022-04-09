import Foundation
import RxSwift
import RxCocoa

extension ObservableType {
  /// Retries the source observable sequence on error using a provided retry
  /// strategy.
  /// - parameter maxAttemptCount: Maximum number of times to repeat the
  /// sequence. `Int.max` by default.
  /// - parameter shouldRetry: Always retruns `true` by default.
  public func retry(_ maxAttemptCount: Int = Int.max,
                    delay: DelayOptions,
                    shouldRetry: @escaping (Error) -> Bool = { _ in true }) -> Observable<E> {
    return retryWhen { (errors: Observable<Error>) in
      return errors
        .enumerated()
        .flatMap { attempt, error -> Observable<Void> in
          guard shouldRetry(error), maxAttemptCount > attempt + 1 else {
            return .error(error)
          }

          let timer = Observable<Int>
            .timer(RxTimeInterval(delay.make(attempt + 1)), scheduler: MainScheduler.instance)
            .map { _ in () }

          return timer
      }
    }
  }

  public func autoRetryOnNetworkError(_ maxAttemptCount: Int = Int.max) -> Observable<E> {
    let shouldRetry: (Error) -> Bool = { error in
      let nserror = error as NSError
      switch nserror.code {
      case NSURLErrorNotConnectedToInternet,
           NSURLErrorCannotLoadFromNetwork,
           NSURLErrorNetworkConnectionLost,
           NSURLErrorCallIsActive,
           NSURLErrorInternationalRoamingOff,
           NSURLErrorDataNotAllowed,
           NSURLErrorCannotConnectToHost,
           NSURLErrorCannotFindHost,
           NSURLErrorDNSLookupFailed,
           NSURLErrorRedirectToNonExistentLocation,
           NSURLErrorTimedOut:
        return true
      default:
        return false
      }
    }
    return retry(delay: .exponential(initial: 3, multiplier: 1.5, maxDelay: 10), shouldRetry: shouldRetry)
  }
}

public enum DelayOptions {
  case immediate()
  case constant(time: Double)
  case exponential(initial: Double, multiplier: Double, maxDelay: Double)
  case custom(closure: (Int) -> Double)
}

public extension DelayOptions {
  func make(_ attempt: Int) -> Double {
    switch self {
    case .immediate: return 0.0
    case .constant(let time): return time
    case .exponential(let initial, let multiplier, let maxDelay):
      // if it's first attempt, simply use initial delay, otherwise calculate delay
      let delay = attempt == 1 ? initial : initial * pow(multiplier, Double(attempt - 1))
      return min(maxDelay, delay)
    case .custom(let closure): return closure(attempt)
    }
  }
}
