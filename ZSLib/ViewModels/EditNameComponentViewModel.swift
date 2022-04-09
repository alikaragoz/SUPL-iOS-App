import Foundation
import RxSwift
import RxCocoa

public protocol EditNameComponentViewModelInputs {
  // call to configure with string
  func configureWith(name: String)
  
  // string value of name textfield text
  func nameChanged(_ name: String)
  
  // call when the tap the return key on the keyboard
  func nameTextFieldDoneEditing()
  
  // call when submit button is pressed
  func submitButtonPressed()
  
  // call when the view will appear
  func viewWillAppear()

  // call when the dismiss action has been made
  func didPressDismiss()

  // call when the view did dismiss
  func didDismiss()
}

public protocol EditNameComponentViewModelOutputs {
  // emits text that should be put into the name field
  var nameText: Observable<String> { get }
  
  // bool value whether the name is valid
  var isValid: Observable<Bool> { get }

  // emits with a string when the submit button is pressed
  var shouldSubmit: Observable<String> { get }

  // emits whether the view should be dismissed with a confirmation prompt
  var shouldDismiss: Observable<Bool> { get }
  
  // emits a boolean that determines if the keyboard should be shown or not
  var showKeyboard: Observable<Bool> { get }
}

public protocol EditNameComponentViewModelType {
  var inputs: EditNameComponentViewModelInputs { get }
  var outputs: EditNameComponentViewModelOutputs { get }
}

public final class EditNameComponentViewModel: EditNameComponentViewModelType,
  EditNameComponentViewModelInputs,
EditNameComponentViewModelOutputs {

  public var inputs: EditNameComponentViewModelInputs { return self }
  public var outputs: EditNameComponentViewModelOutputs { return self }
  
  public init() {

    nameText = Observable.merge(
      nameChangedProperty.asObservable(),
      nameProperty.asObservable()
    )

    isValid = nameText.map { $0.isEmpty == false }
    
    shouldSubmit = Observable.merge(
      submitButtonPressedProperty,
      nameTextFieldDoneEditingProperty)
      .withLatestFrom(nameText)
      .map { $0.trimmed() }

    showKeyboard = Observable.merge(
      viewWillAppearProperty.map { _ in true },
      didDismissProperty.map { _ in false }
    )

    shouldDismiss = didPressDismissProperty
      .withLatestFrom(Observable.combineLatest(nameProperty, nameText))
      .map { originalName, editedName in
        return originalName != editedName
    }
  }

  // MARK: - Inputs

  private let nameChangedProperty = PublishSubject<String>()
  public func nameChanged(_ name: String) {
    self.nameChangedProperty.onNext(name)
  }

  private let nameProperty = BehaviorRelay<String>(value: "")
  public func configureWith(name: String) {
    self.nameProperty.accept(name)
  }
  
  private let nameTextFieldDoneEditingProperty = PublishSubject<Void>()
  public func nameTextFieldDoneEditing() {
    self.nameTextFieldDoneEditingProperty.onNext(())
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

  public var isValid: Observable<Bool>
  public var nameText: Observable<String>
  public var shouldSubmit: Observable<String>
  public var shouldDismiss: Observable<Bool>
  public var showKeyboard: Observable<Bool>
}
