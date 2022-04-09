import MobileCoreServices
import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

final class FilePicker: NSObject {

  public enum Mode {
    case image
    case video

    public var fileTypes: [String] {
      switch self {
      case .image: return [String(kUTTypeImage)]
      case .video: return [String(kUTTypeMovie), String(kUTTypeMPEG4)]
      }
    }
  }

  let viewModel: FilePickerViewModelType = FilePickerViewModel()
  private let disposeBag = DisposeBag()
  private var modes: [Mode]
  weak var hostViewController: UIViewController?
  public var allowsMultipleSelection: Bool = true

  // MARK: - Init
  
  override init() {
    self.modes = [.image]
    super.init()
    bindViewModel()
  }

  convenience init(modes: [Mode] = [.image]) {
    self.init()
    self.modes = modes
  }
  
  // MARK: - Bindings
  
  private func bindViewModel() {
    viewModel.outputs.shouldShowPickerSource
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.showPickerSource()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldTakeVideo
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.takeVideo()
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldTakePicture
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.takePicture()
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldShowImagePicker
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.showImagePicker()
      })
      .disposed(by: disposeBag)
    
    viewModel.outputs.shouldShowDocumentPicker
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.showDocumentPicker()
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Picker Sources
  
  internal func showPickerSource() {
    let actionSheet = UIAlertController.universalActionSheet()

    if self.modes.contains(.video) {
      // take a video
      let takeVideoActionTitle = NSLocalizedString(
        "file_picker.action_sheet.picker_source.take_video.title",
        value: "Take a video",
        comment: "Title of the action to show the camera and take a video.")
      let takeVideoAction = UIAlertAction(
        title: takeVideoActionTitle,
        style: .default,
        handler: { [weak self] _ in
          self?.viewModel.inputs.takeVideoButtonPressed()
      })
      actionSheet.addAction(takeVideoAction)
    }

    if self.modes.contains(.image) {
      // take a picture
      let takePictureActionTitle = NSLocalizedString(
        "file_picker.action_sheet.picker_source.take_picture.title",
        value: "Take a picture",
        comment: "Title of the action to show the camera and take a picture.")
      let takePictureAction = UIAlertAction(
        title: takePictureActionTitle,
        style: .default,
        handler: { [weak self] _ in
          self?.viewModel.inputs.takePictureButtonPressed()
      })
      actionSheet.addAction(takePictureAction)
    }
    
    // image picker
    let imagePickerActionTitle = NSLocalizedString(
      "file_picker.action_sheet.picker_source.image_picker.title",
      value: "Photo Library",
      comment: "Title of the action to show the Photo Library.")
    let imagePickerAction = UIAlertAction(
      title: imagePickerActionTitle,
      style: .default,
      handler: { [weak self] _ in
        self?.viewModel.inputs.imagePickerButtonPressed()
    })
    actionSheet.addAction(imagePickerAction)
    
    // document picker
    let documentPickerActionTitle = NSLocalizedString(
      "file_picker.action_sheet.picker_source.document_picker.title",
      value: "Documents",
      comment: "Title of the action to show the Document Picker.")
    let documentPickerAction = UIAlertAction(
      title: documentPickerActionTitle,
      style: .default,
      handler: { [weak self] _ in
        self?.viewModel.inputs.documentPickerButtonPressed()
    })
    actionSheet.addAction(documentPickerAction)
    
    // cancel
    let cancelPickerActionTitle = NSLocalizedString(
      "file_picker.action_sheet.picker_source.cancel.title",
      value: "Cancel",
      comment: "Title of the action to cancel.")
    let cancelPickerAction = UIAlertAction(title: cancelPickerActionTitle, style: .cancel, handler: nil)
    actionSheet.addAction(cancelPickerAction)
    
    self.hostViewController?.present(actionSheet, animated: true, completion: nil)
  }
  
  // MARK: - Image Picker
  
  internal func showImagePicker() {
    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
      let imagePicker = UIImagePickerController()
      imagePicker.delegate = self
      imagePicker.sourceType = .photoLibrary
      imagePicker.videoQuality = .typeHigh
      imagePicker.mediaTypes = self.modes.flatMap { $0.fileTypes }
      self.hostViewController?.present(imagePicker, animated: true, completion: nil)
    }
  }
  
  // MARK: - Camera
  
  internal func takePicture() {
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let imagePicker = UIImagePickerController()
      imagePicker.delegate = self
      imagePicker.sourceType = .camera
      imagePicker.mediaTypes = [String(kUTTypeImage)]
      self.hostViewController?.present(imagePicker, animated: true, completion: nil)
    }
  }

  internal func takeVideo() {
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let imagePicker = UIImagePickerController()
      imagePicker.delegate = self
      imagePicker.sourceType = .camera
      imagePicker.allowsEditing = true
      imagePicker.videoQuality = .typeHigh
      imagePicker.mediaTypes = [String(kUTTypeMovie), String(kUTTypeMPEG4)]
      self.hostViewController?.present(imagePicker, animated: true, completion: nil)
    }
  }
  
  // MARK: - Document Picker
  
  internal func showDocumentPicker() {
    let documentController =
      UIDocumentPickerViewController(
        documentTypes: self.modes.flatMap { $0.fileTypes },
        in: .import
    )
    documentController.delegate = self
    documentController.allowsMultipleSelection = self.allowsMultipleSelection
    self.hostViewController?.present(documentController, animated: true, completion: nil)
  }
}

// MARK: - UIImagePickerControllerDelegate

extension FilePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  public func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

    if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
      self.handleImagePickerResult(withFileUrl: videoUrl)
    } else if let imageUrl = info[UIImagePickerController.InfoKey.imageURL] as? URL {
      self.handleImagePickerResult(withFileUrl: imageUrl)
    } else if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
      self.viewModel.inputs.imagePicked(image: editedImage)
    } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
      self.viewModel.inputs.imagePicked(image: originalImage)
    } else {
      trackRuntimeError("not able to properly get a media")
      return
    }

    picker.dismiss(animated: true, completion: nil)
  }
  
  public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }

  private func handleImagePickerResult(withFileUrl url: URL) {
    guard let type = Media.type(forFileUrl: url) else {
      trackRuntimeError("file not supported (\(url.pathExtension))")
      return
    }

    let media = Media(url: url, type: type)
    viewModel.inputs.mediasPicked(medias: [media])
  }
}

// MARK: - UIImagePickerControllerDelegate

extension FilePicker: UIDocumentPickerDelegate {
  
  public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    
    guard
      let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
        trackRuntimeError("caches should be set")
        return
    }

    var medias: [Media] = []

    for url in urls {
      let ext = url.pathExtension
      let fileUrl = URL(fileURLWithPath: caches).appendingPathComponent("\(UUID().uuidString).\(ext)")
      try? FileManager.default.moveItem(atPath: url.path, toPath: fileUrl.path)

      guard let type = Media.type(forFileUrl: fileUrl) else {
        trackRuntimeError("file not supported (\(fileUrl.pathExtension))")
        return
      }

      medias.append(Media(url: fileUrl, type: type))
    }
    
    viewModel.inputs.mediasPicked(medias: medias)
    controller.dismiss(animated: true, completion: nil)
  }
  
  public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
}
