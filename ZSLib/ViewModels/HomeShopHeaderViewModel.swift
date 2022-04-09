import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol HomeShopHeaderViewModelInputs {
  // call to configure with a shop
  func configureWith(shop: Shop)
}

public protocol HomeShopHeaderViewModelOutputs {
  // emits a url
  var url: Observable<String> { get }

  // emits a name
  var name: Observable<String> { get }

  // emits a logo url
  var logoUrl: Observable<URL> { get }
}

public protocol HomeShopHeaderViewModelType {
  var inputs: HomeShopHeaderViewModelInputs { get }
  var outputs: HomeShopHeaderViewModelOutputs { get }
}

public final class HomeShopHeaderViewModel: HomeShopHeaderViewModelType,
  HomeShopHeaderViewModelInputs,
HomeShopHeaderViewModelOutputs {

  public var inputs: HomeShopHeaderViewModelInputs { return self }
  public var outputs: HomeShopHeaderViewModelOutputs { return self }

  public init() {
    let defaultName = NSLocalizedString(
      "home_shop_header.shop_name",
      value: "Your Shop",
      comment: "Placeholder Name of the shop that appear on the header of the home")

    let defaultUrl = NSLocalizedString(
      "home_shop_header.shop_url",
      value: "https://your-shop.supl.co",
      comment: "Placeholder url name of the shop that appear on the header of the home")

    let shop = configureWithProp.asObservable().unwrap().share(replay: 1)

    name = shop.map { $0.conf?.companyInfo?.name }.map {
      guard let name = $0 else { return defaultName }
      return name.isEmpty ? defaultName : name
    }

    url = shop.map { $0.domain }.map {
      return $0.isEmpty ? defaultUrl : $0
    }

    logoUrl = shop.map { $0.conf?.companyInfo?.logo?.url }.unwrap()
  }

  // MARK: - Inputs

  private let configureWithProp = BehaviorRelay<Shop?>(value: nil)
  public func configureWith(shop: Shop) {
    self.configureWithProp.accept(shop)
  }

  // MARK: - Outputs

  public var url: Observable<String>
  public var name: Observable<String>
  public var logoUrl: Observable<URL>
}
