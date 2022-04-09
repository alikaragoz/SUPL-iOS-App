// swiftlint:disable force_unwrapping
import Foundation
import RxTest
import RxSwift
import XCTest

final class MaterializedElementsTests: XCTestCase {
  private var testScheduler: TestScheduler!
  private var eventObservable: Observable<Event<Int>>!
  private let dummyError = NSError(domain: "dummy", code: -102)
  private var disposeBag = DisposeBag()

  override func setUp() {
    super.setUp()
    testScheduler = TestScheduler(initialClock: 0)
    eventObservable = testScheduler.createHotObservable([
      Recorded.next(0, Event.next(0)),
      Recorded.next(100, Event.next(1)),
      Recorded.next(200, Event.error(dummyError)),
      Recorded.next(300, Event.next(2)),
      Recorded.next(400, Event.error(dummyError)),
      Recorded.next(500, Event.next(3))
      ]).asObservable()
  }

  override func tearDown() {
    super.tearDown()
    disposeBag = DisposeBag()
  }

  func test_elementsReturnsOnlyNextEvents() {
    let observer = testScheduler.createObserver(Int.self)

    eventObservable
      .elements()
      .subscribe(observer)
      .disposed(by: disposeBag)
    testScheduler.start()

    XCTAssertEqual(observer.events, [
      Recorded.next(0, 0),
      Recorded.next(100, 1),
      Recorded.next(300, 2),
      Recorded.next(500, 3)
      ])
  }

  func test_errorsReturnsOnlyErrorEvents() {
    let observer = testScheduler.createObserver(Error.self)

    eventObservable
      .errors()
      .subscribe(observer)
      .disposed(by: disposeBag)
    testScheduler.start()

    XCTAssertEqual(observer.events.map { $0.time }, [200, 400])
    XCTAssertEqual(observer.events.map { $0.value.element! as NSError }, [dummyError, dummyError])
  }
}
