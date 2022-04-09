import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public enum ProductEditionComponentMode {
  case edition
  case review
}

public protocol ProductEditionComponentViewModelInputs {
  // call to configure
  func configureWith(shop: Shop, editProduct: EditProduct)

  // call when medias have been added
  func didAddMedias(_ medias: [Media])

  // call when files have been deleted
  func didDeleteFiles(_ pictures: [EditPicture])

  // call when name is pressed
  func namePressed()

  // call when name is price
  func pricePressed()

  // call when description is pressed
  func descriptionPressed()

  // call when stock is pressed
  func stockPressed()

  // call to update the name
  func updateName(_ name: String)

  // call to update the description
  func updateDescription(_ description: String?)

  // call to update the priceInfo
  func updatePrice(_ priceInfo: PriceInfo)

  // call to update the stock
  func updateStock(editStock: EditStock)

  // call to update the online state
  func updateOnlineState(online: Bool)

  // call when the files have been reordered
  func reorderedPictures(_ pictures: [EditPicture])

  // call to set the mode of the component
  func setMode(_ mode: ProductEditionComponentMode)

  // call when the user taps the submit button
  func submitButtonPressed()

  // call when dimissing
  func didDismiss()

  // call when the view did load
  func viewDidLoad()
}

public protocol ProductEditionComponentViewModelOutputs {
  // emits formatted text that should be used in name label
  var name: Observable<String> { get }

  // emits formatted text that should be used in price label
  var price: Observable<String> { get }

  // emits formatted text that should be used in description label
  var description: Observable<String> { get }

  // emits the online state
  var online: Observable<Bool> { get }

  // emits formatted text that should be used in stock label
  var stock: Observable<(productId: String, shopId: String, editStock: EditStock)> { get }

  // emits the list of the EditPicture used in the product
  var initialPictures: Observable<[EditPicture]> { get }

  // emits whether the edition is valid
  var isValid: Observable<Bool> { get }

  // emits when the mode is set
  var mode: Observable<ProductEditionComponentMode> { get }

  // emits the list of the EditPicture added to the product
  var newPictures: Observable<[EditPicture]> { get }

  // emits the list of the EditPicture deleted from to the product
  var deletedPictures: Observable<[EditPicture]> { get }

  // emits when the name edition view should be displayed
  var shouldPresentNameEdition: Observable<EditProduct> { get }

  // emits when the price edition view should be displayed
  var shouldPresentPriceEdition: Observable<EditProduct> { get }

  // emits when the description edition view should be displayed
  var shouldPresentDescriptionEdition: Observable<EditProduct> { get }

  // emits when the stock edition view should be displayed
  var shouldPresentStockEdition: Observable<(productId: String, shopId: String, editStock: EditStock)> { get }

  // emits when the edition should save the current EditProduct
  var shouldSubmit: Observable<EditProduct> { get }

  // emits when the coordinator should dismiss
  var shouldDismiss: Observable<Bool> { get }
}

public protocol ProductEditionComponentViewModelType {
  var inputs: ProductEditionComponentViewModelInputs { get }
  var outputs: ProductEditionComponentViewModelOutputs { get }
}

public final class ProductEditionComponentViewModel: ProductEditionComponentViewModelType,
  ProductEditionComponentViewModelInputs,
ProductEditionComponentViewModelOutputs {

  public var inputs: ProductEditionComponentViewModelInputs { return self }
  public var outputs: ProductEditionComponentViewModelOutputs { return self }
  private let disposeBag = DisposeBag()

  public init() {
    let configure = self.configureProperty.unwrap()
    let editProduct = configure.map { $0.editProduct }
    let shop = configure.map { $0.shop }
    
    let updatedEditProduct = BehaviorRelay<EditProduct?>(value: self.configureProperty.value?.editProduct)
    let editProductUnwrapped = updatedEditProduct.unwrap()
    let refProduct = editProductUnwrapped.take(1)
    
    viewDidLoadProperty.withLatestFrom(editProduct).subscribe(onNext: {
      updatedEditProduct.accept($0)
    }).disposed(by: disposeBag)
    
    updateNameProperty.subscribe(onNext: {
      var ep = updatedEditProduct.value
      ep?.name = $0
      updatedEditProduct.accept(ep)
    }).disposed(by: disposeBag)
    
    updateDescriptionProperty.subscribe(onNext: {
      var ep = updatedEditProduct.value
      ep?.description = $0
      updatedEditProduct.accept(ep)
    }).disposed(by: disposeBag)
    
    updatePriceProperty.subscribe(onNext: {
      var ep = updatedEditProduct.value
      ep?.priceInfo = $0
      updatedEditProduct.accept(ep)
    }).disposed(by: disposeBag)
    
    updateStockProperty.subscribe(onNext: {
      var ep = updatedEditProduct.value
      ep?.stock = $0
      updatedEditProduct.accept(ep)
    }).disposed(by: disposeBag)

    updateOnlineStateProp.subscribe(onNext: {
      var ep = updatedEditProduct.value
      ep?.disabled = !$0
      updatedEditProduct.accept(ep)
    }).disposed(by: disposeBag)
    
    newPictures = didAddMediasProperty
      .withLatestFrom(Observable.combineLatest(didAddMediasProperty, shop))
      .map { medias, shop in
        var ep = updatedEditProduct.value
        let addedPictures = medias.map { media -> EditPicture in
          let p = EditPicture(url: media.url)
          p.kind = media.isImage
            ? Visual.Kind.photo.rawValue
            : Visual.Kind.cloudflareVideo.rawValue
          p.startProcess(shopId: shop.id)
          return p
        }
        let pictures = (ep?.pictures ?? []) + addedPictures
        ep?.pictures = pictures
        updatedEditProduct.accept(ep)
        return addedPictures
    }
    
    reorderedPicturesProperty.subscribe(onNext: { editPictures in
      var ep = updatedEditProduct.value
      ep?.pictures = editPictures
      updatedEditProduct.accept(ep)
    }).disposed(by: disposeBag)
    
    didDeleteFilesProperty.subscribe(onNext: { deletedPictures in
      var ep = updatedEditProduct.value
      ep?.pictures?.removeAll(where: { picture in
        return deletedPictures.contains(where: { $0.url == picture.url })
      })
      updatedEditProduct.accept(ep)
    }).disposed(by: disposeBag)
    
    isValid = editProductUnwrapped.map { $0.isValid }
    
    name = editProductUnwrapped
      .map { $0.name ?? "" }
    
    price = editProductUnwrapped
      .map { $0.priceInfo }
      .unwrap()
      .map {
        Format.currency(Double($0.amount) / 100,
                        currencySymbol: Currency.currencySymbolFrom(currencyCode: $0.currency))
    }
    
    description = editProductUnwrapped
      .map { $0.description }
      .unwrap()
      .map {
        let charLimit = 100
        return ($0.description.count <= charLimit)
          ? $0.description
          : String($0.description.prefix(charLimit)).trimmed() + "..."
    }
    
    stock = Observable
      .combineLatest(editProductUnwrapped, shop)
      .map { args in
        guard let editStock = args.0.stock else {
          trackRuntimeError("We should have a Product Id and a Stock")
          return nil
        }
        return (productId: args.0.id, shopId: args.1.id, editStock: editStock)
      }
      .unwrap()

    online = editProductUnwrapped
      .map { !($0.disabled ?? false) }
    
    initialPictures = viewDidLoadProperty
      .withLatestFrom(Observable.combineLatest(editProductUnwrapped, shop))
      .map { args in
        args.0.pictures?.forEach { $0.startProcess(shopId: args.1.id) }
        return args.0.pictures
      }
      .unwrap()

    mode = viewDidLoadProperty.withLatestFrom(setModeProp.unwrap())
    
    deletedPictures = didDeleteFilesProperty
    shouldPresentNameEdition = namePressedProperty.withLatestFrom(editProductUnwrapped)
    shouldPresentPriceEdition = pricePressedProperty.withLatestFrom(editProductUnwrapped)
    shouldPresentDescriptionEdition = descriptionPressedProperty.withLatestFrom(editProductUnwrapped)
    shouldPresentStockEdition = stockPressedProperty.withLatestFrom(stock)
    shouldSubmit = submitButtonPressedProperty.withLatestFrom(editProductUnwrapped)
    shouldDismiss = didDismissProperty
      .withLatestFrom(Observable.combineLatest(refProduct, editProductUnwrapped))
      .map { $0.0 != $0.1 }
  }

  // MARK: - Inputs
  private typealias ConfigureParams = (shop: Shop, editProduct: EditProduct)
  private let configureProperty = BehaviorRelay<ConfigureParams?>(value: nil)
  public func configureWith(shop: Shop, editProduct: EditProduct) {
    self.configureProperty.accept((shop: shop, editProduct: editProduct))
  }

  private let updateNameProperty = PublishSubject<String>()
  public func updateName(_ name: String) {
    self.updateNameProperty.onNext(name)
  }

  private let updateDescriptionProperty = PublishSubject<String?>()
  public func updateDescription(_ description: String?) {
    self.updateDescriptionProperty.onNext(description)
  }

  private let updatePriceProperty = PublishSubject<PriceInfo>()
  public func updatePrice(_ priceInfo: PriceInfo) {
    self.updatePriceProperty.onNext(priceInfo)
  }

  private let updateStockProperty = PublishSubject<EditStock>()
  public func updateStock(editStock: EditStock) {
    self.updateStockProperty.onNext(editStock)
  }

  private let updateOnlineStateProp = PublishSubject<Bool>()
  public func updateOnlineState(online: Bool) {
    self.updateOnlineStateProp.onNext(online)
  }

  private let didDeleteFilesProperty = PublishSubject<[EditPicture]>()
  public func didDeleteFiles(_ files: [EditPicture]) {
    self.didDeleteFilesProperty.onNext(files)
  }

  private let namePressedProperty = PublishSubject<Void>()
  public func namePressed() {
    self.namePressedProperty.onNext(())
  }

  private let pricePressedProperty = PublishSubject<Void>()
  public func pricePressed() {
    self.pricePressedProperty.onNext(())
  }

  private let descriptionPressedProperty = PublishSubject<Void>()
  public func descriptionPressed() {
    self.descriptionPressedProperty.onNext(())
  }

  private let stockPressedProperty = PublishSubject<Void>()
  public func stockPressed() {
    self.stockPressedProperty.onNext(())
  }

  private let viewDidLoadProperty = PublishSubject<Void>()
  public func viewDidLoad() {
    self.viewDidLoadProperty.onNext(())
  }

  private let submitButtonPressedProperty = PublishSubject<Void>()
  public func submitButtonPressed() {
    self.submitButtonPressedProperty.onNext(())
  }

  private let didAddMediasProperty = PublishSubject<[Media]>()
  public func didAddMedias(_ medias: [Media]) {
    self.didAddMediasProperty.onNext(medias)
  }

  private let didDismissProperty = PublishSubject<Void>()
  public func didDismiss() {
    self.didDismissProperty.onNext(())
  }

  private let reorderedPicturesProperty = PublishSubject<[EditPicture]>()
  public func reorderedPictures(_ pictures: [EditPicture]) {
    self.reorderedPicturesProperty.onNext(pictures)
  }

  private let setModeProp = BehaviorRelay<ProductEditionComponentMode?>(value: nil)
  public func setMode(_ mode: ProductEditionComponentMode) {
    self.setModeProp.accept(mode)
  }

  // MARK: - Outputs

  public var shouldDismiss: Observable<Bool>
  public var name: Observable<String>
  public var price: Observable<String>
  public var deletedPictures: Observable<[EditPicture]>
  public var description: Observable<String>
  public var online: Observable<Bool>
  public var initialPictures: Observable<[EditPicture]>
  public var isValid: Observable<Bool>
  public var mode: Observable<ProductEditionComponentMode>
  public var newPictures: Observable<[EditPicture]>
  public var shouldPresentNameEdition: Observable<EditProduct>
  public var shouldPresentPriceEdition: Observable<EditProduct>
  public var shouldPresentDescriptionEdition: Observable<EditProduct>
  public var shouldPresentStockEdition: Observable<(productId: String, shopId: String, editStock: EditStock)>
  public var shouldSubmit: Observable<EditProduct>
  public var stock: Observable<(productId: String, shopId: String, editStock: EditStock)>
}
