import UIKit

public class FloatButton: UIButton {

  struct Constants {
    static let animationDuration: TimeInterval = 0.15
    struct Shadow {
      struct Default {
        static let opacity: Float = 0.3
        static let radius: CGFloat = 2.0
        static let offset: CGSize = .init(width: 0, height: 1)
      }

      struct Highlighted {
        static let opacity: Float = 0.2
        static let radius: CGFloat = 6.0
        static let offset: CGSize = .init(width: 0, height: 4)
      }
    }
  }

  private var backgroundColors: [UInt: UIColor] = [:]

  // MARK: - Init

  public convenience init() {
    self.init(type: .custom)
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
    // disable default highlight state
    adjustsImageWhenHighlighted = false
    showsTouchWhenHighlighted = false

    // block users from activating multiple buttons simultaneously by default.
    isExclusiveTouch = true

    // Default shadow
    layer.masksToBounds = false
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowRadius = Constants.Shadow.Default.radius
    layer.shadowOffset = Constants.Shadow.Default.offset
    layer.shadowOpacity = Constants.Shadow.Default.opacity
  }

  // MARK: - UIControl methods

  override public var isEnabled: Bool {
    get {
      return super.isEnabled
    }
    set {
      setEnabled(newValue, animated: false)
    }
  }

  override public var isHighlighted: Bool {
    didSet {
      updateAfterStateChange(animated: true)
    }
  }

  private func setEnabled(_ enabled: Bool, animated: Bool) {
    super.isEnabled = enabled
    updateAfterStateChange(animated: animated)
  }

  private func updateAfterStateChange(animated: Bool) {
    updateBackgroundColor(animated: animated)
  }

  // MARK: - UIResponder

  override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    adjustShadow(highlighted: true)
  }

  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    adjustShadow(highlighted: false)
  }

  override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    adjustShadow(highlighted: false)
  }

  // MARK: - Shadow

  private func shadowOffsetAnimationWith(highlighted: Bool) -> CABasicAnimation {
    let fromValue = highlighted
      ? Constants.Shadow.Default.offset
      : Constants.Shadow.Highlighted.offset

    let toValue = highlighted
      ? Constants.Shadow.Highlighted.offset
      : Constants.Shadow.Default.offset

    let animation = CABasicAnimation(keyPath: "shadowOffset")
    animation.fromValue = fromValue
    animation.toValue = toValue
    return animation
  }

  private func shadowRadiusAnimationWith(highlighted: Bool) -> CABasicAnimation {
    let fromValue = highlighted
      ? Constants.Shadow.Default.radius
      : Constants.Shadow.Highlighted.radius

    let toValue = highlighted
      ? Constants.Shadow.Highlighted.radius
      : Constants.Shadow.Default.radius

    let animation = CABasicAnimation(keyPath: "shadowRadius")
    animation.fromValue = fromValue
    animation.toValue = toValue
    return animation
  }

  private func shadowOpacityAnimationWith(highlighted: Bool) -> CABasicAnimation {
    let fromValue = highlighted
      ? Constants.Shadow.Default.opacity
      : Constants.Shadow.Highlighted.opacity

    let toValue = highlighted
      ? Constants.Shadow.Highlighted.opacity
      : Constants.Shadow.Default.opacity

    let animation = CABasicAnimation(keyPath: "shadowOpacity")
    animation.fromValue = fromValue
    animation.toValue = toValue
    return animation
  }

  private func adjustShadow(highlighted: Bool) {

    let group = CAAnimationGroup()
    group.duration = Constants.animationDuration
    group.animations = [
      shadowOffsetAnimationWith(highlighted: highlighted),
      shadowRadiusAnimationWith(highlighted: highlighted),
      shadowOpacityAnimationWith(highlighted: highlighted)
    ]
    layer.add(group, forKey: "shadowAnimations")

    layer.shadowRadius = Constants.Shadow.Default.radius
    layer.shadowOffset = Constants.Shadow.Default.offset
    
    layer.shadowOffset = highlighted
      ? Constants.Shadow.Highlighted.offset
      : Constants.Shadow.Default.offset

    layer.shadowRadius = highlighted
      ? Constants.Shadow.Highlighted.radius
      : Constants.Shadow.Default.radius

    layer.shadowOpacity = highlighted
      ? Constants.Shadow.Highlighted.opacity
      : Constants.Shadow.Default.opacity
  }

  // MARK: - Background Color

  private func updateBackgroundColor(animated: Bool) {
    if animated {
      UIView.animate(withDuration: Constants.animationDuration, animations: updateBackgroundColor)
    } else {
      updateBackgroundColor()
    }
  }

  private func updateBackgroundColor() {
    guard let backgroundColor = backgroundColors[state.rawValue] else { return }
    self.backgroundColor = backgroundColor
  }

  public func backgroundColor(_ color: UIColor, for state: UIControl.State) {
    backgroundColors[state.rawValue] = color
    updateBackgroundColor()
  }
}
