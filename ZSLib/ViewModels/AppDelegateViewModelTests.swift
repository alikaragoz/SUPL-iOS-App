// swiftlint:disable force_unwrapping
import RxCocoa
import RxSwift
import RxTest
import XCTest
@testable import ZSLib

class AppDelegateViewModelTests: TestCase {
  private let vm: AppDelegateViewModelType = AppDelegateViewModel()
  private var configureFabric = TestScheduler(initialClock: 0).createObserver(Void.self)
  
  override func setUp() {
    super.setUp()
    _ = self.vm.outputs.configureFabric.subscribe(configureFabric)
  }

  func testConfigureFabricNotInRelease() {
    let debugBundle = MockBundle(bundleIdentifier: SUPLBundleIdentifier.debug.rawValue)
    withEnvironment(mainBundle: debugBundle) {
      self.vm.inputs.applicationDidFinishLaunching(application: UIApplication.shared, launchOptions: nil)
      XCTAssertEqual(configureFabric.events.count, 0)
    }
  }

  func testConfigureFabricInRelease() {
    let releaseBundle = MockBundle(bundleIdentifier: SUPLBundleIdentifier.release.rawValue)
    withEnvironment(mainBundle: releaseBundle) {
      self.vm.inputs.applicationDidFinishLaunching(application: UIApplication.shared, launchOptions: nil)
      XCTAssertEqual(configureFabric.events.count, 1)
    }
  }
}
