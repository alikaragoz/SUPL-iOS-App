import UIKit
import Kingfisher
import RxSwift
import ZSAPI
import ZSLib
import ZSPrelude

public protocol ProductAddCellDelegate: class {
  func productAddCelldidTap()
}

public final class ProductAddCell: StaticCollectionViewCell {

  struct Constants {
    static let cornerRadius: CGFloat = 10.0
    static let borderWidth: CGFloat = 2.0
    static let borderDashPattern: [NSNumber] = [6, 6, 6, 6]
  }

  var addNewProductButton = FloatButton().then {
    let addImage = image(named: "add")
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.setImage(addImage, for: .normal)
    $0.tintColor = .white
    $0.sizeToFit()
    _ = $0 |> blackFloatButtonStyle <> squareFloatButtonStyle
  }

  private var dashedBorderLayer: CAShapeLayer?
  internal weak var delegate: ProductAddCellDelegate?

  // MARK: Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.do {
      $0.backgroundColor = .clear
      $0.layer.masksToBounds = true
    }

    addNewProductButton.do {
      contentView.addSubview($0)
      $0.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
      $0.addTarget(self, action: #selector(addNewProductButtonPressed), for: .touchUpInside)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    updateDashedBorder()
  }

  // MARK: - Style

  private func updateDashedBorder() {
    self.dashedBorderLayer?.removeFromSuperlayer()

    let color = UIColor.zs_light_gray.cgColor
    let dashedBorderLayer = CAShapeLayer()
    let frameSize = self.bounds.size
    let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)

    dashedBorderLayer.bounds = shapeRect
    dashedBorderLayer.position = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
    dashedBorderLayer.fillColor = UIColor.clear.cgColor
    dashedBorderLayer.strokeColor = color
    dashedBorderLayer.lineWidth = Constants.borderWidth
    dashedBorderLayer.lineJoin = CAShapeLayerLineJoin.round
    dashedBorderLayer.lineDashPattern = Constants.borderDashPattern
    dashedBorderLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: Constants.cornerRadius).cgPath

    self.layer.addSublayer(dashedBorderLayer)
    self.dashedBorderLayer = dashedBorderLayer
  }

  // MARK: - Events

  @objc internal func addNewProductButtonPressed(_ sender: UIButton) {
    self.delegate?.productAddCelldidTap()
  }
}
