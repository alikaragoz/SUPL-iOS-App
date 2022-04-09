import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol LargeProgressCircleViewModelInputs {
  // call when change the progression
  func setProgressionTo(percent: Double)

  // call to start auto progress
  func startSlowProgress()
}

public protocol LargeProgressCircleViewModelOutputs {
  // emits when the progression percentage should change
  var setProgressionPercentage: Observable<Double> { get }

  // emits when the progress needs to be complete
  var shouldFinish: Observable<Bool> { get }

  // emits when the slow progress should kickoff
  var shouldStartSlowProgress: Observable<Void> { get }
}

public protocol LargeProgressCircleViewModelType {
  var inputs: LargeProgressCircleViewModelInputs { get }
  var outputs: LargeProgressCircleViewModelOutputs { get }
}

public final class LargeProgressCircleViewModel: LargeProgressCircleViewModelType,
  LargeProgressCircleViewModelInputs,
LargeProgressCircleViewModelOutputs {

  public var inputs: LargeProgressCircleViewModelInputs { return self }
  public var outputs: LargeProgressCircleViewModelOutputs { return self }

  public init() {
    setProgressionPercentage = setProgressionToProperty
      .distinctUntilChanged()

    shouldFinish = setProgressionPercentage
      .map { $0 >= 1 }
      .delay(0.5, scheduler: AppEnvironment.current.mainScheduler)
      .distinctUntilChanged()

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
  public var shouldFinish: Observable<Bool>
}
