import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol ProgressLineViewModelInputs {
  // call when change the progression
  func setProgressionTo(percent: Double)

  // call to start auto progress
  func startSlowProgress()
}

public protocol ProgressLineViewModelOutputs {
  // emits when the progression percentage should change
  var setProgressionPercentage: Observable<Double> { get }

  // emits when the progress needs to be complete
  var shouldFinish: Observable<Void> { get }

  // emits when the slow progress should kickoff
  var shouldStartSlowProgress: Observable<Void> { get }
}

public protocol ProgressLineViewModelType {
  var inputs: ProgressLineViewModelInputs { get }
  var outputs: ProgressLineViewModelOutputs { get }
}

public final class ProgressLineViewModel: ProgressLineViewModelType,
  ProgressLineViewModelInputs,
ProgressLineViewModelOutputs {

  public var inputs: ProgressLineViewModelInputs { return self }
  public var outputs: ProgressLineViewModelOutputs { return self }

  public init() {
    setProgressionPercentage = setProgressionToProperty
      .distinctUntilChanged()

    shouldFinish = setProgressionPercentage
      .filter { $0 >= 1 }
      .map { _ in () }
      .delay(0.5, scheduler: AppEnvironment.current.mainScheduler)

    shouldStartSlowProgress = startSlowProgressProperty
  }

  // MARK: - Inputs

  private let setProgressionToProperty = BehaviorRelay<Double>(value: 0)
  public func setProgressionTo(percent: Double) {
    self.setProgressionToProperty.accept(percent)
  }

  private let startSlowProgressProperty = PublishSubject<Void>()
  public func startSlowProgress() {
    self.startSlowProgressProperty.onNext(())
  }

  // MARK: - Outputs

  public var setProgressionPercentage: Observable<Double>
  public var shouldStartSlowProgress: Observable<Void>
  public var shouldFinish: Observable<Void>
}
