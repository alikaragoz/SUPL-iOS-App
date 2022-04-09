import Foundation
import RxSwift
import RxCocoa

public protocol EditDescComponentViewModelInputs {
  // call to configure with a string
  func configureWith(description: String)
  
  // string value of description textfield text
  func descriptionChanged(_ description: String)
  
  // call when submit button is pressed
  func submitButtonPressed()
  
  // call when the view will appear
  func viewWillAppear()
  
  // call when the dismiss action has been made
  func didPressDismiss()
  
  // call when the view did dismiss
  func didDismiss()
}

public protocol EditDescComponentViewModelOutputs {
  // emits text that should be put into the description field
  var descriptionText: Observable<String> { get }
  
  // emits whether the palceholder text field needs to be visible
  var isPlaceholderVisible: Observable<Bool> { get }
  
  // emits with a string when the submit button is pressed
  var shouldSubmit: Observable<String> { get }
  
  // emits whether the view should be dismissed with a confirmation prompt
  var shouldDismiss: Observable<Bool> { get }
  
  // emits a boolean that determines if the keyboard should be shown or not
  var showKeyboard: Observable<Bool> { get }
}

public protocol EditDescComponentViewModelType {
  var inputs: EditDescComponentViewModelInputs { get }
  var outputs: EditDescComponentViewModelOutputs { get }
}

public final class EditDescComponentViewModel: EditDescComponentViewModelType,
  EditDescComponentViewModelInputs,
EditDescComponentViewModelOutputs {
  
  public var inputs: EditDescComponentViewModelInputs { return self }
  public var outputs: EditDescComponentViewModelOutputs { return self }
  
  public init() {
    
    let productDescription = editProductProperty
      .map { $0.description }
      .unwrap()
      .asObservable()
    
    let updatedDescription = Observable.merge(descriptionChangedProperty.asObservable(), productDescription)
    
    descriptionText = productDescription
    
    isPlaceholderVisible = updatedDescription.map { $0.isEmpty }
    
    shouldSubmit = submitButtonPressedProperty
      .withLatestFrom(updatedDescription)
    
    showKeyboard = Observable.merge(
      viewWillAppearProperty.map { _ in true },
      didDismissProperty.map { _ in false }
    )
    
    shouldDismiss = didPressDismissProperty
      .withLatestFrom(Observable.combineLatest(productDescription, updatedDescription))
      .map { originalDesc, editedDesc in
        return originalDesc != editedDesc
    }
  }
  
  // MARK: - Inputs
  
  private let descriptionChangedProperty = PublishSubject<String>()
  public func descriptionChanged(_ description: String) {
    self.descriptionChangedProperty.onNext(description)
  }
  
  private let editProductProperty = BehaviorRelay<String>(value: "")
  public func configureWith(description: String) {
    self.editProductProperty.accept(description)
  }
  
  private let submitButtonPressedProperty = PublishSubject<Void>()
  public func submitButtonPressed() {
    self.submitButtonPressedProperty.onNext(())
  }
  
  private let viewWillAppearProperty = PublishSubject<Void>()
  public func viewWillAppear() {
    self.viewWillAppearProperty.onNext(())
  }
  
  private let didDismissProperty = PublishSubject<Void>()
  public func didDismiss() {
    self.didDismissProperty.onNext(())
  }
  
  private let didPressDismissProperty = PublishSubject<Void>()
  public func didPressDismiss() {
    self.didPressDismissProperty.onNext(())
  }
  
  // MARK: - Outputs
  
  public var descriptionText: Observable<String>
  public var isPlaceholderVisible: Observable<Bool>
  public var shouldSubmit: Observable<String>
  public var shouldDismiss: Observable<Bool>
  public var showKeyboard: Observable<Bool>
}
