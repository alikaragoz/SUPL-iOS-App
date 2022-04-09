import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public protocol ProductCreationPictureViewModelInputs {
  // call when back button is pressed
  func backButtonPressed()

  // call when the close button is pressed
  func closeButtonPressed()

  // call when medias have been picked
  func mediasPicked(medias: [Media])

  // call when the view did appear
  func viewDidAppear()
}

public protocol ProductCreationPictureViewModelOutputs {
  // emits when the vc should be dismissed
  var shouldDismiss: Observable<Void> { get }

  // emits when the next button has been pressed
  var shouldGoToNext: Observable<[Media]> { get }

  // emits when the previous button has been pressed
  var shouldGoToPrevious: Observable<Void> { get }
}

public protocol ProductCreationPictureViewModelType {
  var inputs: ProductCreationPictureViewModelInputs { get }
  var outputs: ProductCreationPictureViewModelOutputs { get }
}

public final class ProductCreationPictureViewModel: ProductCreationPictureViewModelType,
  ProductCreationPictureViewModelInputs,
ProductCreationPictureViewModelOutputs {

  public var inputs: ProductCreationPictureViewModelInputs { return self }
  public var outputs: ProductCreationPictureViewModelOutputs { return self }

  private let disposeBag = DisposeBag()

  public init() {
    shouldDismiss = closeButtonPressedProperty
    shouldGoToNext = mediasPickedProperty
    shouldGoToPrevious = backButtonPressedProperty

    viewDidAppearProperty
      .subscribe { _ in AppEnvironment.current.analytics.trackViewedCreateProductPictures() }
      .disposed(by: disposeBag)
  }

  // MARK: - Inputs

  private let backButtonPressedProperty = PublishSubject<Void>()
  public func backButtonPressed() {
    self.backButtonPressedProperty.onNext(())
  }

  private let closeButtonPressedProperty = PublishSubject<Void>()
  public func closeButtonPressed() {
    self.closeButtonPressedProperty.onNext(())
  }

  private let mediasPickedProperty = PublishSubject<[Media]>()
  public func mediasPicked(medias: [Media]) {
    self.mediasPickedProperty.onNext(medias)
  }

  private let viewDidAppearProperty = PublishSubject<Void>()
  public func viewDidAppear() {
    self.viewDidAppearProperty.onNext(())
  }

  // MARK: - Outputs

  public var shouldGoToPrevious: Observable<Void>
  public var shouldGoToNext: Observable<[Media]>
  public var shouldDismiss: Observable<Void>
}
