import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol InPlaceLoaderViewModelInputs {
  // call to start
  func start()

  // call to stop
  func abort()

  // call to complete
  func complete()

  // call when the progress anim finished
  func didFinish()
}

public protocol InPlaceLoaderViewModelOutputs {
  // emits when the progress needs to be started
  var shouldStart: Observable<Void> { get }

  // emits when the progress needs to be aborted
  var shouldAbort: Observable<Void> { get }

  // emits when the progress needs to be completed
  var shouldComplete: Observable<Void> { get }

  // emits when the progress anim finished
  var shouldFinish: Observable<Void> { get }
}

public protocol InPlaceLoaderViewModelType {
  var inputs: InPlaceLoaderViewModelInputs { get }
  var outputs: InPlaceLoaderViewModelOutputs { get }
}

public final class InPlaceLoaderViewModel: InPlaceLoaderViewModelType,
  InPlaceLoaderViewModelInputs,
InPlaceLoaderViewModelOutputs {

  public var inputs: InPlaceLoaderViewModelInputs { return self }
  public var outputs: InPlaceLoaderViewModelOutputs { return self }

  public init() {
    shouldStart = startProp
    shouldAbort = abortProp
    shouldComplete = completeProp
    shouldFinish = didFinishProp
  }

  // MARK: - Inputs

  private let startProp = PublishSubject<Void>()
  public func start() {
    self.startProp.onNext(())
  }

  private let abortProp = PublishSubject<Void>()
  public func abort() {
    self.abortProp.onNext(())
  }
  private let completeProp = PublishSubject<Void>()
  public func complete() {
    self.completeProp.onNext(())
  }

  private let didFinishProp = PublishSubject<Void>()
  public func didFinish() {
    self.didFinishProp.onNext(())
  }

  // MARK: - Outputs

  public var shouldStart: Observable<Void>
  public var shouldAbort: Observable<Void>
  public var shouldComplete: Observable<Void>
  public var shouldFinish: Observable<Void>
}
