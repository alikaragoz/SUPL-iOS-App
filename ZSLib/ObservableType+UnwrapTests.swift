import Foundation
import RxSwift
import RxTest
import XCTest

class UnwrapTests: XCTestCase {
  let numbers: [Int?] = [1, nil, Int?(3), 4]
  private var observer: TestableObserver<Int>!

  override func setUp() {
    super.setUp()

    let scheduler = TestScheduler(initialClock: 0)
    observer = scheduler.createObserver(Int.self)

    _ = Observable.from(numbers)
      .unwrap()
      .subscribe(observer)

    scheduler.start()
  }

  func testUnwrapFilterNil() {
    //test results count
    XCTAssertEqual(
      observer.events.count,
      numbers.count - 1 /* the nr. of nil elements*/ + 1 /* complete event*/
    )
  }

  func testUnwrapResultValues() {
    //test elements values and type
    let correctValues = [
      Recorded.next(0, 1),
      Recorded.next(0, 3),
      Recorded.next(0, 4),
      Recorded.completed(0)
    ]
    XCTAssertEqual(observer.events, correctValues)
  }
}
