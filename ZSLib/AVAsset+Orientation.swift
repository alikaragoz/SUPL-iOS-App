import AVFoundation

extension AVAsset {

  public enum VideoOrientation {
    case right, up, left, down
  }

  public func videoOrientation() -> VideoOrientation? {

    guard let firstVideoTrack = self.tracks(withMediaType: .video).first else {
      return nil
    }

    let radiansToDegrees: (Float) -> CGFloat = { radians in
      return CGFloat(radians * 180.0 / Float.pi)
    }

    let transform = firstVideoTrack.preferredTransform
    let videoAngleInDegree = radiansToDegrees(atan2f(Float(transform.b), Float(transform.a)))
    return VideoOrientation.withAngle(ofDegree: videoAngleInDegree)
  }

}

extension AVAsset.VideoOrientation {
  static func withAngle(ofDegree degree: CGFloat) -> AVAsset.VideoOrientation? {
    switch Int(degree) {
    case 0: return .right
    case 90: return .up
    case 180: return .left
    case -90: return .down
    default: return nil
    }
  }
}
