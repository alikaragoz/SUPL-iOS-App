import Foundation
import RxSwift
import RxCocoa
import ZSAPI
import ZSPrelude

public enum ShopEditionPaypal {
  case notConnected
  case connectedMissingInfo
  case connected(email: String)
}

public protocol ShopEditionViewModelInputs {
  // call to configure with EditShop
  func configureWith(editShop: EditShop)

  // call when the user taps the submit button
  func submitButtonPressed()

  // call when dimissing
  func didDismiss()

  // call when logo is pressed
  func logoPressed()

  // call when name is pressed
  func namePressed()

  // call when domain is pressed
  func domainPressed()

  // call when paypal is pressed
  func paypalPressed()

  // call to update the name
  func updateName(_ name: String)

  // call to update the domain
  func updateDomain(_ domain: String)

  // call to inform a paypal update happened
  func updatePaypal()

  // call when the view did load
  func viewDidLoad()

  // call when the view did appear
  func viewDidAppear()

  // call when a picture has been picked
  func didPickPicture(_ url: URL)
}

public protocol ShopEditionViewModelOutputs {
  var logoUrl: Observable<URL> { get }

  // emits text that should be used in name label
  var name: Observable<String> { get }

  // emits text that should be used in name label
  var domain: Observable<String> { get }

  // emits text that should be used in paypal label
  var paypal: Observable<ShopEditionPaypal> { get }

  // emits when the name edition should be shown
  var shouldPresentNameEdition: Observable<EditShop> { get }

  // emits when the domain edition should be shown
  var shouldPresentDomainEdition: Observable<EditShop> { get }

  // emits when the paypal connect should be shown
  var shouldPresentPaypalEdition: Observable<Shop> { get }

  // emits when the view should submit
  var shouldSubmit: Observable<EditShop> { get }

  // emits when the view should dismiss
  var shouldDismiss: Observable<Bool> { get }
}

public protocol ShopEditionViewModelType {
  var inputs: ShopEditionViewModelInputs { get }
  var outputs: ShopEditionViewModelOutputs { get }
}

public class ShopEditionViewModel: ShopEditionViewModelType,
  ShopEditionViewModelInputs,
ShopEditionViewModelOutputs {

  public var inputs: ShopEditionViewModelInputs { return self }
  public var outputs: ShopEditionViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    let editShop = self.configureWithEditShopProp.unwrap()

    let updatedEditShop = BehaviorRelay<EditShop?>(value: self.configureWithEditShopProp.value)
    let updatedEditShopUnwrapped = updatedEditShop.unwrap()
    let refEditShop = updatedEditShopUnwrapped.take(1)
    let shouldGoBack = PublishSubject<Void>()

    viewDidLoadProp.withLatestFrom(editShop).subscribe(onNext: {
      updatedEditShop.accept($0)
    }).disposed(by: disposeBag)

    updateNameProp.subscribe(onNext: {
      var companyInfo = updatedEditShop.value?.conf?.companyInfo ?? EditCompanyInfo()
      companyInfo.name = $0
      var editShop = updatedEditShop.value
      editShop?.conf?.companyInfo = companyInfo
      updatedEditShop.accept(editShop)
    }).disposed(by: disposeBag)

    updateDomainProp.subscribe(onNext: {
      var editShop = updatedEditShop.value
      editShop?.domain = $0
      updatedEditShop.accept(editShop)
    }).disposed(by: disposeBag)

    didPickPictureProp
      .withLatestFrom(Observable.combineLatest(updatedEditShopUnwrapped, didPickPictureProp))
      .map { args -> EditPicture in
        let ep = EditPicture(url: args.1)
        ep.startProcess(shopId: args.0.id)
        return ep
      }.subscribe(onNext: {
        var companyInfo = updatedEditShop.value?.conf?.companyInfo ?? EditCompanyInfo()
        companyInfo.editPicture = $0
        var editShop = updatedEditShop.value
        editShop?.conf?.companyInfo = companyInfo
        updatedEditShop.accept(editShop)
      }).disposed(by: disposeBag)

    logoUrl = updatedEditShopUnwrapped
      .map { $0.conf?.companyInfo?.editPicture?.url }
      .unwrap()
      .distinctUntilChanged()

    name = updatedEditShopUnwrapped
      .map { $0.conf?.companyInfo?.name ?? "" }

    domain = updatedEditShopUnwrapped.map { "https://" + $0.domain }

    paypal = Observable.merge(updatedEditShop.map { _ in () }, updatePaypalProp).map {
      if AppEnvironment.current.apiService.session == nil { return .notConnected }
      guard let paypalUser = AppEnvironment.current.userDefaults.paypalUser else {
        return .connectedMissingInfo
      }
      return .connected(email: paypalUser.email)
    }

    shouldPresentNameEdition = namePressedProp.withLatestFrom(updatedEditShopUnwrapped)
    shouldPresentDomainEdition = domainPressedProp.withLatestFrom(updatedEditShopUnwrapped)
    shouldPresentPaypalEdition = paypalPressedProp
      .withLatestFrom(updatedEditShopUnwrapped)
      .map { $0.shop }

    shouldSubmit = submitButtonPressedProp
      .withLatestFrom(
        Observable.combineLatest(updatedEditShopUnwrapped, refEditShop)
      )
      .map {
        if $0.0 != $0.1 {
          return $0.0
        } else {
          shouldGoBack.onNext(())
          return nil
        }
      }
      .unwrap()

    let dismissFromIntent = didDismissProp
      .withLatestFrom(Observable.combineLatest(refEditShop, updatedEditShopUnwrapped))
      .map { $0.0 != $0.1 }

    shouldDismiss = Observable.merge(dismissFromIntent, shouldGoBack.map { false })

    viewDidAppearProp
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedShopEdition() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let configureWithEditShopProp = BehaviorRelay<EditShop?>(value: nil)
  public func configureWith(editShop: EditShop) {
    self.configureWithEditShopProp.accept(editShop)
  }

  private let viewDidLoadProp = PublishSubject<Void>()
  public func viewDidLoad() {
    self.viewDidLoadProp.onNext(())
  }

  private let viewDidAppearProp = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProp.onNext(())
  }

  private let submitButtonPressedProp = PublishSubject<Void>()
  public func submitButtonPressed() {
    self.submitButtonPressedProp.onNext(())
  }

  private let didDismissProp = PublishSubject<Void>()
  public func didDismiss() {
    self.didDismissProp.onNext(())
  }

  private let logoPressedProp = PublishSubject<Void>()
  public func logoPressed() {
    self.logoPressedProp.onNext(())
  }

  private let namePressedProp = PublishSubject<Void>()
  public func namePressed() {
    self.namePressedProp.onNext(())
  }

  private let domainPressedProp = PublishSubject<Void>()
  public func domainPressed() {
    self.domainPressedProp.onNext(())
  }

  private let paypalPressedProp = PublishSubject<Void>()
  public func paypalPressed() {
    self.paypalPressedProp.onNext(())
  }

  private let updateNameProp = PublishSubject<String>()
  public func updateName(_ name: String) {
    self.updateNameProp.onNext(name)
  }

  private let updateDomainProp = PublishSubject<String>()
  public func updateDomain(_ domain: String) {
    self.updateDomainProp.onNext(domain)
  }

  private let updatePaypalProp = PublishSubject<Void>()
  public func updatePaypal() {
    self.updatePaypalProp.onNext(())
  }

  private let didPickPictureProp = PublishSubject<URL>()
  public func didPickPicture(_ url: URL) {
    self.didPickPictureProp.onNext(url)
  }

  // MARK: - Outputs
  public var logoUrl: Observable<URL>
  public var name: Observable<String>
  public var domain: Observable<String>
  public var paypal: Observable<ShopEditionPaypal>
  public var shouldPresentNameEdition: Observable<EditShop>
  public var shouldPresentDomainEdition: Observable<EditShop>
  public var shouldPresentPaypalEdition: Observable<Shop>
  public var shouldDismiss: Observable<Bool>
  public var shouldSubmit: Observable<EditShop>
}
