import AVFoundation

extension AVAsset {
  var videoSize: CGSize? {
    guard let videoTrack = self.tracks.first(where: { $0.mediaType == AVMediaType.video }) else {
      return nil
    }

    let naturalSize = videoTrack.naturalSize
    let isPortrait = (self.videoOrientation() == .up || self.videoOrientation() == .down)

    return CGSize(
      width: isPortrait ? naturalSize.height : naturalSize.width,
      height: isPortrait ? naturalSize.width : naturalSize.height
    )
  }
}
