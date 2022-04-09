import Foundation
import RxSwift
import RxCocoa
import ZSAPI

public struct Media {
  public enum `Type`: String {
    case jpg
    case png
    case mp4
    case mov
  }
  
  public let url: URL
  public let type: Type
  
  public init(url: URL, type: Type) {
    self.url = url
    self.type = type
  }
}

extension Media.`Type`: Equatable {}
extension Media.`Type`: Codable {}

extension Media: Equatable {}
extension Media: Codable {}

extension Media {
  
  public static func from(url: URL) -> Media? {
    guard let type = Media.type(forFileUrl: url) else {
      return nil
    }
    return Media(url: url, type: type)
  }
  
  public static func type(forFileUrl url: URL) -> Type? {
    switch url.pathExtension.lowercased() {
    case "jpg", "jpeg": return .jpg
    case "png": return .png
    case "mp4", "mpeg4": return .mp4
    case "mov": return .mov
    default: return nil
    }
  }
  
  var isImage: Bool {
    switch self.type {
    case .jpg, .png: return true
    default: return false
    }
  }
  
  public var isVideo: Bool {
    switch self.type {
    case .mp4, .mov: return true
    default: return false
    }
  }
}

public protocol FilePickerViewModelInputs {
  // call when add files button is pressed
  func addFilesButtonPressed()
  
  // call whent the document picker button is pressed
  func documentPickerButtonPressed()
  
  // call when medias have been picked in the image picker
  func mediasPicked(medias: [Media])
  
  // call when an image has been picked
  func imagePicked(image: UIImage)
  
  // call when the image picker button is pressed
  func imagePickerButtonPressed()
  
  // call whent the take picture button is pressed
  func takePictureButtonPressed()
  
  // call whent the take video button is pressed
  func takeVideoButtonPressed()
}

public protocol FilePickerViewModelOutputs {
  // emits when some files have been picked
  var didPickMedias: Observable<[Media]> { get }
  
  // emits when we should take a picture
  var shouldTakePicture: Observable<Void> { get }
  
  // emits when we should take a video
  var shouldTakeVideo: Observable<Void> { get }
  
  // emits when the document picker should be shown
  var shouldShowDocumentPicker: Observable<Void> { get }
  
  // emits when the image picker should be shown
  var shouldShowImagePicker: Observable<Void> { get }
  
  // emits when the source picker should be shown
  var shouldShowPickerSource: Observable<Void> { get }
}

public protocol FilePickerViewModelType {
  var inputs: FilePickerViewModelInputs { get }
  var outputs: FilePickerViewModelOutputs { get }
}

public final class FilePickerViewModel: FilePickerViewModelType,
  FilePickerViewModelInputs,
FilePickerViewModelOutputs {
  
  enum ViewModelError: Error, LocalizedError {
    case imagePreparation
    case cacheNotSet
    case imageToCache
    
    public var errorDescription: String? {
      switch self {
      case .imagePreparation: return "imagePreparation"
      case .cacheNotSet: return "cacheNotSet"
      case .imageToCache: return "imageToCache"
      }
    }
  }
  
  public var inputs: FilePickerViewModelInputs { return self }
  public var outputs: FilePickerViewModelOutputs { return self }
  
  public init() {
    didPickMedias = Observable.merge(
      mediasPickedProperty.flatMap(prepareImagesFromMedia),
      imagePickedProperty.flatMap(prepareImage).map(Media.from).unwrap().map { [$0] }
    )
    shouldShowDocumentPicker = documentPickerButtonPressedProperty
    shouldShowImagePicker = imagePickerButtonPressedProperty
    shouldShowPickerSource = addFilesButtonPressedProperty
    shouldTakePicture = takePictureButtonPressedProperty
    shouldTakeVideo = takeVideoButtonPressedProperty
  }
  
  // MARK: - Inputs
  
  private let addFilesButtonPressedProperty = PublishSubject<Void>()
  public func addFilesButtonPressed() {
    self.addFilesButtonPressedProperty.onNext(())
  }
  
  private let documentPickerButtonPressedProperty = PublishSubject<Void>()
  public func documentPickerButtonPressed() {
    self.documentPickerButtonPressedProperty.onNext(())
  }
  
  private let mediasPickedProperty = PublishSubject<[Media]>()
  public func mediasPicked(medias: [Media]) {
    self.mediasPickedProperty.onNext(medias)
  }
  
  private let imagePickedProperty = PublishSubject<UIImage>()
  public func imagePicked(image: UIImage) {
    self.imagePickedProperty.onNext(image)
  }
  
  private let imagePickerButtonPressedProperty = PublishSubject<Void>()
  public func imagePickerButtonPressed() {
    self.imagePickerButtonPressedProperty.onNext(())
  }
  
  private let takePictureButtonPressedProperty = PublishSubject<Void>()
  public func takePictureButtonPressed() {
    self.takePictureButtonPressedProperty.onNext(())
  }
  
  private let takeVideoButtonPressedProperty = PublishSubject<Void>()
  public func takeVideoButtonPressed() {
    self.takeVideoButtonPressedProperty.onNext(())
  }
  
  // MARK: - Outputs
  
  public var didPickMedias: Observable<[Media]>
  public var shouldTakePicture: Observable<Void>
  public var shouldTakeVideo: Observable<Void>
  public var shouldShowPickerSource: Observable<Void>
  public var shouldShowImagePicker: Observable<Void>
  public var shouldShowDocumentPicker: Observable<Void>
}

private func prepareImagesFromMedia(_ medias: [Media]) -> Observable<[Media]> {
  let o = medias.map { media -> Observable<Media> in
    guard media.isImage else {
      return Observable.of(media)
    }
    
    return Observable.of(media)
      .map { UIImage(contentsOfFile: $0.url.path) }
      .unwrap()
      .flatMap(prepareImage)
      .map { return Media(url: $0, type: media.type) }
  }
  
  return Observable
    .from(o)
    .merge()
    .toArray()
}

private func prepareImage(_ image: UIImage) -> Observable<URL> {
  return Observable.of(image)
    .observeOn(AppEnvironment.current.backgroundScheduler)
    .flatMap(optimizeImage)
    .flatMap { saveImageToCache($0.0, ext: $0.1) }
}

private func optimizeImage(_ image: UIImage) -> Observable<(Data, String)> {
  let resizedImage = image.scaled(toLongEdge: 2000)
  
  guard let orientationFixed = resizedImage.orientationFixed else {
    trackRuntimeError("orientationFixed should be set ")
    return .error(FilePickerViewModel.ViewModelError.imagePreparation)
  }
  
  let data: Data?
  let ext: String
  switch orientationFixed.isOpaque {
  case true:
    data = orientationFixed.jpegData(compressionQuality: 0.9)
    ext = "jpg"
  case false:
    data = orientationFixed.pngData()
    ext = "png"
  }
  
  guard let d = data else {
    trackRuntimeError("data should be set ")
    return .error(FilePickerViewModel.ViewModelError.imagePreparation)
  }
  return .just((d, ext))
}

private func saveImageToCache(_ imageData: Data, ext: String) -> Observable<URL> {
  guard
    let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
    else {
      trackRuntimeError("Caches should be set")
      return .error(FilePickerViewModel.ViewModelError.cacheNotSet)
  }
  
  let fileUrl = URL(fileURLWithPath: caches).appendingPathComponent("\(UUID().uuidString).\(ext)")
  
  do {
    try imageData.write(to: fileUrl, options: [.atomic])
    return .just(fileUrl)
  } catch {
    return .error(FilePickerViewModel.ViewModelError.imageToCache)
  }
}
