import XCTest
@testable import ZSAPI
@testable import ZSLib

final class AppEnvironmentTests: XCTestCase {

  func testLoginLogout() {
    AppEnvironment.pushEnvironment()
    XCTAssertNil(AppEnvironment.current.apiService.session)

    AppEnvironment.login(Session(id: "deadbeef", user: "beefdead"))
    XCTAssertEqual("deadbeef", AppEnvironment.current.apiService.session?.id)
    XCTAssertEqual("beefdead", AppEnvironment.current.apiService.session?.user)

    AppEnvironment.logout()
    XCTAssertNil(AppEnvironment.current.apiService.session)

    AppEnvironment.popEnvironment()
  }

  func testPushAndPopEnvironment() {
    let lang = AppEnvironment.current.language
    
    AppEnvironment.pushEnvironment()
    XCTAssertEqual(lang, AppEnvironment.current.language)
    
    AppEnvironment.pushEnvironment(language: .fr)
    XCTAssertEqual(Language.fr, AppEnvironment.current.language)
    
    AppEnvironment.pushEnvironment(Environment(language: .en))
    XCTAssertEqual(Language.en, AppEnvironment.current.language)
    
    AppEnvironment.popEnvironment()
    XCTAssertEqual(Language.fr, AppEnvironment.current.language)
    
    AppEnvironment.popEnvironment()
    XCTAssertEqual(lang, AppEnvironment.current.language)
    
    AppEnvironment.popEnvironment()
  }
  
  func testReplaceCurrentEnvironment() {
    
    AppEnvironment.pushEnvironment(language: .fr)
    XCTAssertEqual(AppEnvironment.current.language, Language.fr)
    
    AppEnvironment.pushEnvironment(language: .en)
    XCTAssertEqual(AppEnvironment.current.language, Language.en)
    
    AppEnvironment.replaceCurrentEnvironment(language: Language.fr)
    XCTAssertEqual(AppEnvironment.current.language, Language.fr)
    
    AppEnvironment.popEnvironment()
    XCTAssertEqual(AppEnvironment.current.language, Language.fr)
    
    AppEnvironment.popEnvironment()
  }
  
  func testReplaceEnvironment() {
    AppEnvironment.replaceCurrentEnvironment(language: Language.fr)
    XCTAssertEqual(AppEnvironment.current.language, Language.fr)
  }
  
  func testPersistenceKey() {
    XCTAssertEqual("co.supl.AppEnvironment.current", AppEnvironment.environmentStorageKey,
                   "Failing this test means you better have a good reason.")
  }

  func testSession() {
    AppEnvironment.pushEnvironment()

    XCTAssertNil(AppEnvironment.current.apiService.session)

    AppEnvironment.login(Session(id: "deadbeef", user: "beefdead"))
    XCTAssertEqual("deadbeef", AppEnvironment.current.apiService.session?.id)
    XCTAssertEqual("beefdead", AppEnvironment.current.apiService.session?.user)

    AppEnvironment.logout()
    XCTAssertNil(AppEnvironment.current.apiService.session)

    AppEnvironment.popEnvironment()
  }

  func testSaveEnvironment() {
    let apiService = MockService(
      serverConfig: ServerConfig(
        apiBaseUrl: URL(string: "http://tests.supl.co")!,
        environment: .local
      ),
      session: Session(id: "deadbeef", user: "beefdead")
    )

    let userDefaults = MockKeyValueStore()

    AppEnvironment.saveEnvironment(environment: Environment(apiService: apiService),
                                   userDefaults: userDefaults)

    let result = userDefaults.dictionary(forKey: AppEnvironment.environmentStorageKey)!

    XCTAssertEqual("deadbeef", result["apiService.session.id"] as? String)
    XCTAssertEqual("beefdead", result["apiService.session.user"] as? String)
    XCTAssertEqual("http://tests.supl.co", result["apiService.serverConfig.apiBaseUrl"] as? String)
    XCTAssertEqual("Local", result["apiService.serverConfig.environment"] as? String)
  }

  func testFromStorageWithNothingStored() {
    let userDefaults = MockKeyValueStore()
    let env = AppEnvironment.fromStorage(userDefaults: userDefaults)

    XCTAssertNil(env.apiService.session?.id)
  }

  /*
  func testFromStorageWithFullDataStored() {
    let userDefaults = MockKeyValueStore()

    userDefaults.set(
      [
        "apiService.serverConfig.apiBaseUrl": "http://tests.supl.co",
        "apiService.serverConfig.environment": "Production",
        "apiService.session.id": "deadbeef",
        "apiService.session.user": "beefdead"
      ],
      forKey: AppEnvironment.environmentStorageKey)

    let env = AppEnvironment.fromStorage(userDefaults: userDefaults)

    XCTAssertEqual("http://tests.supl.co", env.apiService.serverConfig.apiBaseUrl.absoluteString)
    XCTAssertEqual("Production", env.apiService.serverConfig.environment.rawValue)
    XCTAssertEqual("deadbeef", env.apiService.session?.id)
    XCTAssertEqual("beefdead", env.apiService.session?.user)

    let differentEnv = AppEnvironment.fromStorage(userDefaults: MockKeyValueStore())
    XCTAssertNil(differentEnv.apiService.session?.id)
    XCTAssertNil(differentEnv.apiService.session?.user)
  }
 */
}
