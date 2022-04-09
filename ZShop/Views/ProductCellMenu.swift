import UIKit
import ZSPrelude
import ZSLib

final public class ProductCellMenu: UIView {

  internal enum Callback {
    case edit
    case share
    case preview
  }
  internal var callback: ((Callback) -> Void)?

  private let editButton = roundButtonWith(imageNamed: "edit-pencil")
  private let shareButton = roundButtonWith(imageNamed: "share")
  private let previewButton = roundButtonWith(imageNamed: "view")

  private let editLabel = subtitleLabelWith(text: NSLocalizedString(
    "product_card_menu.edit_button.title",
    value: "Edit",
    comment: "Subtitle of the button under the product card to edit a product")
  )

  private let shareLabel = subtitleLabelWith(text: NSLocalizedString(
    "product_card_menu.share_button.title",
    value: "Share",
    comment: "Subtitle of the button under the product card to share a product")
  )

  private let previewLabel = subtitleLabelWith(text: NSLocalizedString(
    "product_card_menu.preview_button.title",
    value: "Preview",
    comment: "Subtitle of the button under the product card to preview a product")
  )

  // MARK: - Init

  public convenience init() {
    self.init(frame: .zero)
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }

  private func setup() {
    self.do {
      $0.clipsToBounds = false
      $0.backgroundColor = .clear
    }

    editButton.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor, multiplier: 1.0).isActive = true
      $0.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
    }

    shareButton.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: editButton.rightAnchor, constant: 30.0).isActive = true
      $0.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor, multiplier: 1.0).isActive = true
      $0.addTarget(self, action: #selector(shareButtonPressed), for: .touchUpInside)
    }

    previewButton.do {
      self.addSubview($0)
      $0.leftAnchor.constraint(equalTo: shareButton.rightAnchor, constant: 30.0).isActive = true
      $0.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
      $0.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
      $0.widthAnchor.constraint(equalTo: $0.heightAnchor, multiplier: 1.0).isActive = true
      $0.addTarget(self, action: #selector(previewButtonPressed), for: .touchUpInside)
    }

    editLabel.do {
      self.addSubview($0)
      $0.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 4).isActive = true
      $0.centerXAnchor.constraint(equalTo: editButton.centerXAnchor).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 70.0).isActive = true
    }

    shareLabel.do {
      self.addSubview($0)
      $0.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 4).isActive = true
      $0.centerXAnchor.constraint(equalTo: shareButton.centerXAnchor).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 70.0).isActive = true
    }

    previewLabel.do {
      self.addSubview($0)
      $0.topAnchor.constraint(equalTo: previewButton.bottomAnchor, constant: 4).isActive = true
      $0.centerXAnchor.constraint(equalTo: previewButton.centerXAnchor).isActive = true
      $0.widthAnchor.constraint(equalToConstant: 70.0).isActive = true
    }
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    editButton.layer.cornerRadius = editButton.bounds.height / 2
    shareButton.layer.cornerRadius = shareButton.bounds.height / 2
    previewButton.layer.cornerRadius = previewButton.bounds.height / 2
  }

  // MARK: - Events

  @objc internal func editButtonPressed() {
    callback?(.edit)
  }

  @objc internal func shareButtonPressed() {
    callback?(.share)
  }

  @objc internal func previewButtonPressed() {
    callback?(.preview)
  }

  // MARK: - Factory

  private static func roundButtonWith(imageNamed i: String) -> UIButton {
    return UIButton(type: .custom).then {
      $0.layer.masksToBounds = true
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.clipsToBounds = true

      let newImage = image(named: i, tintColor: .zs_black)?.scaled(to: CGSize(width: 18, height: 18))
      $0.setImage(newImage, for: .normal)
      $0.imageView?.contentMode = .center

      $0.tintColor = .zs_black
      $0.setBackgroundColor(.zs_empty_view_gray, for: .normal)
      $0.setBackgroundColor(UIColor.zs_empty_view_gray.withBrightnessDelta(0.01), for: .highlighted)
      $0.setBackgroundColor(UIColor.zs_empty_view_gray.withAlphaComponent(0.5), for: .disabled)
    }
  }

  private static func subtitleLabelWith(text: String) -> UILabel {
    return UILabel().then {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
      $0.textAlignment = .center
      $0.backgroundColor = .clear
      $0.numberOfLines = 0
      $0.lineBreakMode = .byWordWrapping
      $0.textColor = .zs_black
      $0.text = text
    }
  }
}
