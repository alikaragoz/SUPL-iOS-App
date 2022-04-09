/**
 Supported languages.
 */
public enum Language: String, CaseIterable {
  case en
  case fr

  public init?(languageString language: String) {
    switch language.lowercased() {
    case "en":
      self = .en
    case "fr":
      self = .fr
    default:
      return nil
    }
  }
  
  public init?(languageStrings languages: [String]) {
    guard let language = languages
      .lazy
      .map({ String($0.prefix(2)) })
      .compactMap(Language.init(languageString:))
      .first else {
        return nil
    }
    self = language
  }
  
  public var displayString: String {
    switch self {
    case .en:
      return "English"
    case .fr:
      return "French"
    }
  }
}
