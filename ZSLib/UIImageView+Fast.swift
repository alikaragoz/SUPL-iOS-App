import UIKit
import Kingfisher

extension UIImageView {
  public func setImageWithFast(fromUrl url: URL) {
    let fastUrl = url.optimized(
      width: Int(self.bounds.size.width),
      height: Int(self.bounds.size.height)
    )
    self.kf.setImage(with: fastUrl, options: [.transition(.fade(0.2))])
  }
}
