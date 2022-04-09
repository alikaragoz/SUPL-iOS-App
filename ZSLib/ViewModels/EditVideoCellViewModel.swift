import AVFoundation
import Foundation
import ZSAPI
import RxSwift
import RxCocoa

public protocol EditVideoCellViewModelInputs {
  // call to configure with EditPicture
  func configureWith(picture: EditPicture)

  // call to inform of the cell size
  func setSize(_ size: CGSize)
}

public protocol EditVideoCellViewModelOutputs {
  // emits an URL of the image
  var image: Observable<URL> { get }
}

public protocol EditVideoCellViewModelType {
  var inputs: EditVideoCellViewModelInputs { get }
  var outputs: EditVideoCellViewModelOutputs { get }
}

public class EditVideoCellViewModel: EditVideoCellViewModelType,
  EditVideoCellViewModelInputs,
EditVideoCellViewModelOutputs {

  public var inputs: EditVideoCellViewModelInputs { return self }
  public var outputs: EditVideoCellViewModelOutputs { return self }

  public init() {
    let picture = self.pictureProperty.unwrap()
    let size = self.sizeProperty.filter { $0 != .zero }.unwrap()

    image = picture.map { $0.thumbnail?.url }
      .unwrap()
      .flatMap { url -> Observable<(URL, CGSize)> in
        Observable.combineLatest(Observable.just(url), size)
      }
      .map {
        if $0.0.isFileURL {
          return $0.0
        } else {
          return $0.0.optimized(
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
