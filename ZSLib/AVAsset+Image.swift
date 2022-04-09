import AVFoundation

extension AVAsset {
  public func image(at time: CMTime = CMTime.zero) throws -> UIImage {
    let imageGenerator = AVAssetImageGenerator(asset: self)
    imageGenerator.appliesPreferredTrackTransform = true
    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
    return UIImage(cgImage: cgImage)
  }
}
