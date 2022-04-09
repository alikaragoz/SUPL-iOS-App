import Foundation
import Crashlytics

public func trackRuntimeError(_ message: String? = nil,
                              error: Error? = nil,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line) {
  print("\n🚫 [\(file) -> \(function) • \(line)]\n\tMessage: \(message!)")
  if let error = error {
    print("\tError: \(error.localizedDescription)")
  }
  print("\n")

  if AppEnvironment.current.mainBundle.isDebug || AppEnvironment.current.mainBundle.isLocal {
    fatalError()
  }

  if AppEnvironment.current.mainBundle.isRelease {
    recordCrashlyticsError(message, error: error, file: file, function: function, line: line)
  }
}

private func recordCrashlyticsError(_ message: String?,
                                    error: Error?,
                                    file: String,
                                    function: String,
                                    line: Int) {

  let fileName = URL(string: "file")?.lastPathComponent
  let identifier = "\(String(describing: fileName)) -> \(function)[\(line)]"

  let crashlyticsError = NSError(domain: identifier, code: 1, userInfo: nil)
  var infos = [String: Any]()

  infos["identifier"] = identifier
  infos["fileName"] = fileName
  infos["function"] = function
  infos["line"] = line
  if let error = error { infos["error"] = error }
  if let message = message { infos["message"] = message }

  Crashlytics.sharedInstance().recordError(crashlyticsError, withAdditionalUserInfo: infos)
}

public func doCatchAndTrackError(message: String? = nil,
                                 file: String = #file,
                                 function: String = #function,
                                 closure: () throws -> Void) {
  do {
    try closure()
  } catch let error {
    trackRuntimeError(message, error: error, file: file, function: function)
  }
}
