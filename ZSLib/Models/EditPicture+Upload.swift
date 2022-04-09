import AVFoundation
import RxCocoa
import RxSwift
import ZSAPI

extension EditPicture {
  
  public enum EditPictureError: Error, LocalizedError {
    case couldNotGetImageSize
    case couldNotGetVisual
    case couldNotGetVideoSize
    case couldNotGetThumb
    case couldNotSaveThumb
    case cachesDirNotSet
    case thumbProcessShouldBeSet
    
    public var errorDescription: String? {
      switch self {
      case .couldNotGetImageSize: return "couldNotGetImageSize"
      case .couldNotGetVisual: return "couldNotGetVisual"
      case .couldNotGetVideoSize: return "couldNotGetVideoSize"
      case .couldNotGetThumb: return "couldNotGetThumb"
      case .couldNotSaveThumb: return "couldNotSaveThumb"
      case .cachesDirNotSet: return "cachesDirNotSet"
      case .thumbProcessShouldBeSet: return "thumbProcessShouldBeSet"
      }
    }
  }
  
  public func startProcess(shopId: String) {
    switch self.url.isFileURL {
    case true:
      let process: Observable<EditPicture>
      switch kind {
      case Visual.Kind.photo.rawValue:
        self.populatePhotoInfos()
        process = EditPicture.uploadImageFromFileUrl(editPicture: self, shopId: shopId)
          .autoRetryOnNetworkError()
          .share(replay: 1, scope: .forever)
      case Visual.Kind.cloudflareVideo.rawValue:
        self.populateVideoInfos()
        process = EditPicture.uploadVideoFromFileUrl(editPicture: self, shopId: shopId)
          .autoRetryOnNetworkError()
          .share(replay: 1, scope: .forever)
      default: return
      }
      let disposable = process.subscribe()
      self.process = process
      self.disposable = disposable
    case false:
      self.process = .just(self)
    }
  }

  public func populatePhotoInfos() {
    guard self.kind == Visual.Kind.photo.rawValue else { return }

    guard
      let imageData = try? Data(contentsOf: self.url),
      let imageSize = imageData.imageSize else {
        trackRuntimeError("Could not get image size", error: EditPictureError.couldNotGetImageSize)
        return
    }
    self.width = Int(imageSize.width)
    self.height = Int(imageSize.height)
  }

  public func populateVideoInfos() {
    guard self.kind == Visual.Kind.cloudflareVideo.rawValue else { return }

    let asset = AVURLAsset(url: self.url)

    guard let size = asset.videoSize else {
      trackRuntimeError("Could not video size", error: EditPictureError.couldNotGetVideoSize)
      return
    }

    guard let thumbnail = try? asset.image() else {
      trackRuntimeError("Could not get thumb", error: EditPictureError.couldNotGetThumb)
      return
    }

    guard let thumbFileUrl = try? EditPicture.saveImageToCache(thumbnail) else {
      trackRuntimeError("Could not save thumb", error: EditPictureError.couldNotSaveThumb)
      return
    }

    self.thumbnail = EditPicture(url: thumbFileUrl)
    self.width = Int(size.width)
    self.height = Int(size.height)
  }

  private static func uploadVideoFromFileUrl(editPicture: EditPicture,
                                             shopId: String) -> Observable<EditPicture> {
    return TUSService()
      .upload(file: editPicture.url)
      .autoRetryOnNetworkError()
      .flatMap { url -> Observable<EditPicture> in
      editPicture.thumbnail?.startProcess(shopId: shopId)
      guard let thumbProcess = editPicture.thumbnail?.process else {
        return .error(EditPictureError.thumbProcessShouldBeSet)
      }
      let updateWithVideoUrl = EditPicture.updateWithVideoUrl(editPicture: editPicture, withUrl: url)
      return Observable.combineLatest(updateWithVideoUrl, thumbProcess).map { $0.0 }
    }
  }

  private static func uploadImageFromFileUrl(editPicture: EditPicture,
                                             shopId: String) -> Observable<EditPicture> {
    let mediaType: MediaType = {
      switch editPicture.url.pathExtension.lowercased() {
      case "jpg":
        return .jpg
      case "png":
        return .png
      default:
        return .jpg
      }
    }()
    
    return AppEnvironment.current.apiService.createMedia(shopId: shopId, mediaType: mediaType)
      .flatMap {
        AppEnvironment.current.apiUploadService
          .upload(uploadRequest: $0, file: editPicture.url)
          .autoRetryOnNetworkError()
      }
      .flatMap {
        EditPicture.updateWithApiResponse(editPicture: editPicture, withApiResponse: $0)
    }
  }
  
  private static func updateWithApiResponse(editPicture: EditPicture,
                                            withApiResponse response: FileUploadCompleteResponse)
    -> Observable<EditPicture> {
      editPicture.url = response.mediaUrl
      return .just(editPicture)
  }

  private static func updateWithVideoUrl(editPicture: EditPicture,
                                         withUrl url: URL) -> Observable<EditPicture> {
    editPicture.url = url
    return .just(editPicture)
  }

  private static func saveImageToCache(_ image: UIImage) throws -> URL {
    let data = image.jpegData(compressionQuality: 1.0)
    let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first

    guard let c = caches else {
      throw EditPictureError.cachesDirNotSet
    }

    let fileUrl = URL(fileURLWithPath: c).appendingPathComponent("\(UUID().uuidString).jpg")
    try data?.write(to: fileUrl, options: .atomic)
    return fileUrl
  }
}
