// swiftlint:disable force_unwrapping
import Foundation
import RxTest
import RxSwift
import XCTest

final class CatchErrorAndContinueTests: XCTestCase {
  private var testScheduler: TestScheduler!
  private var eventObservable: Observable<Int>!
  private let dummyError = NSError(domain: "", code: 42)
  private var disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()
    testScheduler = TestScheduler(initialClock: 0)
    eventObservable = testScheduler.createHotObservable([
      Recorded.next(0, 0),
      Recorded.next(100, 1),
      Recorded.error(200, dummyError),
      Recorded.next(300, 2)
      ]).asObservable()
  }

  override func tearDown() {
    super.tearDown()
    disposeBag = DisposeBag()
  }

  func testCatchErrorAndContinue() {
    let observer = testScheduler.createObserver(Int.self)

    eventObservable
      .catchErrorAndContinue(handler: { _ in })
      .subscribe(observer)
      .disposed(by: disposeBag)

    testScheduler.start()

    XCTAssertEqual(observer.events, [
      Recorded.next(0, 0),
      Recorded.next(100, 1),
      Recorded.next(300, 2)
      ])
  }
}
