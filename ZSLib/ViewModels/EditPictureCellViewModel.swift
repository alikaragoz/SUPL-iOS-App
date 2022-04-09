import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol EditPictureCellViewModelInputs {
  // call to configure with EditPicture
  func configureWith(picture: EditPicture)

  // call to inform of the cell size
  func setSize(_ size: CGSize)
}

public protocol EditPictureCellViewModelOutputs {
  // emits an URL of the image
  var image: Observable<URL> { get }
}

public protocol EditPictureCellViewModelType {
  var inputs: EditPictureCellViewModelInputs { get }
  var outputs: EditPictureCellViewModelOutputs { get }
}

public class EditPictureCellViewModel: EditPictureCellViewModelType,
  EditPictureCellViewModelInputs,
EditPictureCellViewModelOutputs {

  public var inputs: EditPictureCellViewModelInputs { return self }
  public var outputs: EditPictureCellViewModelOutputs { return self }

  public init() {

    image = Observable
      .combineLatest(
        pictureProperty.unwrap(),
        sizeProperty.filter { $0 != .zero }.unwrap()
      )
      .map {
        if $0.0.url.isFileURL {
          return $0.0.url
        } else {
          return $0.0.url.optimized(
            width: Int($0.1.width * UIScreen.main.scale),
            height: Int($0.1.height * UIScreen.main.scale))
        }
      }
      .unwrap()
  }

  // MARK: - Inputs

  private let pictureProperty = BehaviorRelay<EditPicture?>(value: nil)
  public func configureWith(picture: EditPicture) {
    self.pictureProperty.accept(picture)
  }

  private let sizeProperty = BehaviorRelay<CGSize?>(value: .zero)
  public func setSize(_ size: CGSize) {
    self.sizeProperty.accept(size)
  }

  // MARK: - Outputs

  public var image: Observable<URL>
}
