extension Shop {
  internal struct Templates {
    internal static let fromApiService = Shop(id: "deadbeaf", conf: nil, domain: "dead-beef")
    internal static let fromPersistentStore = Shop(id: "beafdead", conf: nil, domain: "dead-beef")
    internal static let fromUpdate = Shop(id: "beafdead", conf: .template, domain: "dead-beef")
  }
}
