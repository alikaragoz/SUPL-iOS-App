import Foundation
import ZSAPI

public enum AppKeys: String {
  case paypalUser = "co.supl.KeyValueStoreType.paypalUser"
  case shopKey = "co.supl.KeyValueStoreType.shop"
}

public protocol KeyValueStoreType: class {
  func set(_ value: Bool, forKey defaultName: String)
  func set(_ value: Int, forKey defaultName: String)
  func set(_ value: Any?, forKey defaultName: String)
  
  func bool(forKey defaultName: String) -> Bool
  func dictionary(forKey defaultName: String) -> [String: Any]?
  func integer(forKey defaultName: String) -> Int
  func object(forKey defaultName: String) -> Any?
  func string(forKey defaultName: String) -> String?
  func synchronize() -> Bool
  
  func removeObject(forKey defaultName: String)
  var shop: Shop? { get set }
}

extension KeyValueStoreType {

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }

  public var shop: Shop? {
    get {
      guard
        let dictionary = self.object(forKey: AppKeys.shopKey.rawValue) as? [String: Any] else {
          return nil
      }

      let shop: Shop

      do {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        shop = try self.decoder.decode(Shop.self, from: data)
      } catch {
        trackRuntimeError("Coulnd't deserialize `Shop` object from key value store.", error: error)
        return nil
      }

      return shop
    }
    set {
      self.set(newValue.dictionary, forKey: AppKeys.shopKey.rawValue)
    }
  }

  public var paypalUser: PayPalUser? {
    get {
      guard
        let dictionary = self.object(forKey: AppKeys.paypalUser.rawValue) as? [String: Any] else {
          return nil
      }

      let paypalUser: PayPalUser

      do {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
        paypalUser = try JSONDecoder().decode(PayPalUser.self, from: data)
      } catch {
        trackRuntimeError("Coulnd't deserialize `PayPalUser` object from key value store.", error: error)
        return nil
      }

      return paypalUser
    }
    set {
      self.set(newValue.dictionary, forKey: AppKeys.paypalUser.rawValue)
    }
  }
}

extension UserDefaults: KeyValueStoreType {}

extension NSUbiquitousKeyValueStore: KeyValueStoreType {
  public func integer(forKey defaultName: String) -> Int {
    return Int(longLong(forKey: defaultName))
  }
  
  public func set(_ value: Int, forKey defaultName: String) {
    return set(Int64(value), forKey: defaultName)
  }
}

internal class MockKeyValueStore: KeyValueStoreType {
  var store: [String: Any] = [:]
  
  func set(_ value: Bool, forKey defaultName: String) {
    self.store[defaultName] = value
  }
  
  func set(_ value: Int, forKey defaultName: String) {
    self.store[defaultName] = value
  }
  
  func set(_ value: Any?, forKey key: String) {
    self.store[key] = value
  }
  
  func bool(forKey defaultName: String) -> Bool {
    return self.store[defaultName] as? Bool ?? false
  }
  
  func dictionary(forKey key: String) -> [String: Any]? {
    return self.object(forKey: key) as? [String: Any]
  }
  
  func integer(forKey defaultName: String) -> Int {
    return self.store[defaultName] as? Int ?? 0
  }
  
  func object(forKey key: String) -> Any? {
    return self.store[key]
  }
  
  func string(forKey defaultName: String) -> String? {
    return self.store[defaultName] as? String
  }
  
  func removeObject(forKey defaultName: String) {
    self.set(nil, forKey: defaultName)
  }
  
  func synchronize() -> Bool {
    return true
  }
}
