// swiftlint:disable force_try
import XCTest
import OHHTTPStubs
import RxSwift
@testable import ZSAPI
import ZSPrelude

final class UploadServiceTests: XCTestCase {

  let disposeBag = DisposeBag()

  override func tearDown() {
    OHHTTPStubs.removeAllStubs()
    super.tearDown()
  }

  func testUploadPart() {

    _ = stub(condition: isHost("api.supl.test")) { _ in
      let requestData = try! JSONEncoder().encode(FileUploadPart.Templates.request)
      return OHHTTPStubsResponse(data: requestData, statusCode: 200, headers: ["Etag": "deadbeaf"])
    }

    let expectation = self.expectation(description: ("Request should succeed"))

    UploadService().uploadPart(part: FileUploadPart.Templates.request,
                               file: URL(string: "https://api.supl.test")!)
      .subscribe(onNext: {
        XCTAssertEqual($0, FileUploadPart.Templates.response)
        expectation.fulfill()
      }, onError: { _ in
        XCTFail("Error is not an option here.")
      }).disposed(by: disposeBag)

    self.waitForExpectations(timeout: 2, handler: nil)
  }

  func testUploadPartFail() {

    _ = stub(condition: isHost("api.supl.test")) { _ in
      let response = try! JSONEncoder().encode(FileUploadPart.Templates.request)
      return OHHTTPStubsResponse(data: response, statusCode: 400, headers: nil)
    }

    let expectation = self.expectation(description: ("Request should succeed"))

    UploadService().uploadPart(part: FileUploadPart.Templates.request,
                               file: URL(string: "https://api.supl.test")!)
      .subscribe(onNext: { _ in
        XCTFail("Success is not an option here.")
      }, onError: { _ in
        expectation.fulfill()
      }).disposed(by: disposeBag)

    self.waitForExpectations(timeout: 2, handler: nil)
  }

  func testComplete() {

    _ = stub(condition: isHost("api.supl.test")) { _ in
      let response = try! JSONEncoder().encode(FileUploadCompleteResponse.template)
      return OHHTTPStubsResponse(data: response, statusCode: 200, headers: nil)
    }

    let expectation = self.expectation(description: ("Request should succeed"))

    UploadService().complete(completeUrl: FileUploadRequest.template.completeUrl,
                             parts: [FileUploadPart.Templates.response])
      .subscribe(onNext: {
        XCTAssertEqual($0, .template)
        expectation.fulfill()
      }, onError: { _ in
        XCTFail("Error is not an option here.")
      }).disposed(by: disposeBag)

    self.waitForExpectations(timeout: 2, handler: nil)
  }

  func testCompleteFail() {

    _ = stub(condition: isHost("api.supl.test")) { _ in
      let response = try! JSONEncoder().encode(FileUploadCompleteResponse.template)
      return OHHTTPStubsResponse(data: response, statusCode: 400, headers: nil)
    }

    let expectation = self.expectation(description: ("Request should succeed"))

    UploadService().complete(completeUrl: FileUploadRequest.template.completeUrl,
                             parts: [FileUploadPart.Templates.response])
      .subscribe(onNext: { _ in
        XCTFail("Success is not an option here.")
      }, onError: { _ in
        expectation.fulfill()
      }).disposed(by: disposeBag)

    self.waitForExpectations(timeout: 2, handler: nil)
  }

  func testUpload() {

    _ = stub(condition: isHost("api.supl.test") && isMethodPUT()) { _ in
      let requestData = try! JSONEncoder().encode(FileUploadPart.Templates.request)
      return OHHTTPStubsResponse(data: requestData, statusCode: 200, headers: ["Etag": "deadbeaf"])
    }

    _ = stub(condition: isHost("api.supl.test") && isMethodPOST()) { _ in
      let response = try! JSONEncoder().encode(FileUploadCompleteResponse.template)
      return OHHTTPStubsResponse(data: response, statusCode: 200, headers: nil)
    }

    let expectation = self.expectation(description: ("Request should succeed"))

    UploadService().upload(uploadRequest: FileUploadRequest.template,
                           file: URL(string: "https://api.supl.test")!)
      .subscribe(onNext: {
        XCTAssertEqual($0, .template)
        expectation.fulfill()
      }, onError: { _ in
        XCTFail("Error is not an option here.")
      }).disposed(by: disposeBag)

    self.waitForExpectations(timeout: 2, handler: nil)
  }

  func testUploadFail() {

    _ = stub(condition: isHost("api.supl.test") && isMethodPUT()) { _ in
      let requestData = try! JSONEncoder().encode(FileUploadPart.Templates.request)
      return OHHTTPStubsResponse(data: requestData, statusCode: 400, headers: ["Etag": "deadbeaf"])
    }

    _ = stub(condition: isHost("api.supl.test") && isMethodPOST()) { _ in
      let response = try! JSONEncoder().encode(FileUploadCompleteResponse.template)
      return OHHTTPStubsResponse(data: response, statusCode: 200, headers: nil)
    }

    let expectation = self.expectation(description: ("Request should succeed"))

    UploadService().upload(uploadRequest: FileUploadRequest.template,
                           file: URL(string: "https://api.supl.test")!)
      .subscribe(onNext: { _ in
        XCTFail("Success is not an option here.")
      }, onError: { _ in
        expectation.fulfill()
      }).disposed(by: disposeBag)

    self.waitForExpectations(timeout: 2, handler: nil)
  }
}
