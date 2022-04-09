import UIKit
import ZSLib
import ZSPrelude

public final class EditableLabel: TappableView {

  private(set) var textLabel = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
  }

  private var textAttachment = NSTextAttachment().then {
    $0.image = image(named: "edit-pencil", tintColor: .zs_light_gray)
    $0.bounds = .init(x: 0, y: 0, width: 18, height: 18)
  }

  public var placeholderText: String = "" {
    didSet {
      setLabelTo(text: nil)
    }
  }

  public var text: String? = nil {
    didSet {
      setLabelTo(text: text)
    }
  }

  private var placeholderAttributedString: NSMutableAttributedString {
    let range = NSRange(location: 0, length: placeholderText.count)

    let attributes = NSMutableAttributedString(string: placeholderText)
    attributes.addAttributes([.foregroundColor: UIColor.zs_light_gray], range: range)

    return attributes
  }

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
    textLabel.do {
      view.addSubview($0)
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
  }

  // MARK: - Set / Get

  public func setLabelTo(text: String?) {
    let attributedString: NSMutableAttributedString
    if let text = text, text != "" {
      attributedString = NSMutableAttributedString(string: text + "\u{00A0}")
      attributedString.append(NSAttributedString(attachment: textAttachment))
    } else {
      attributedString = placeholderAttributedString
    }
    textLabel.attributedText = attributedString
  }
}
