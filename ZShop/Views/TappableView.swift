import UIKit
import ZSLib
import ZSPrelude

public class TappableView: UIControl {
  
  struct Constants {
    static let showAnimationDuration: TimeInterval = 0.10
    static let hideAnimationDuration: TimeInterval = 0.15
    struct Shadow {
      struct Default {
        static let opacity: Float = 0.0
        static let radius: CGFloat = 0.0
      }
      
      struct Highlighted {
        static let opacity: Float = 0.0 // 0.2
        static let radius: CGFloat = 0.0 // 6.0
      }
    }
  }
  
  private var backgroundColors: [UInt: UIColor] = [:]
  
  private(set) var view = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.backgroundColor = .clear
  }

  public var padding: UIEdgeInsets = .zero {
    didSet {
      topConstraint.constant = padding.top
      bottomConstraint.constant = -padding.bottom
      leftConstraint.constant = padding.left
      rightConstraint.constant = -padding.right
      self.setNeedsUpdateConstraints()
    }
  }
  
  private var topConstraint: NSLayoutConstraint!
  private var bottomConstraint: NSLayoutConstraint!
  private var leftConstraint: NSLayoutConstraint!
  private var rightConstraint: NSLayoutConstraint!
  
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
    // block users from activating multiple buttons simultaneously by default.
    isExclusiveTouch = true
    
    layer.do {
      $0.masksToBounds = false
      $0.shadowColor = UIColor.black.cgColor
      $0.shadowRadius = Constants.Shadow.Default.radius
      $0.shadowOpacity = Constants.Shadow.Default.opacity
      $0.shadowOffset = .init(width: 0, height: 0)
    }
    
    view.do {
      self.addSubview($0)
    }
    
    topConstraint = view.topAnchor.constraint(equalTo: self.topAnchor, constant: padding.top)
    bottomConstraint = view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -padding.bottom)
    leftConstraint = view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: padding.left)
    rightConstraint = view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -padding.right)
    
    let constraints: [NSLayoutConstraint] = [
      topConstraint,
      bottomConstraint,
      leftConstraint,
      rightConstraint
    ]
    
    NSLayoutConstraint.activate(constraints)
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
    self.superview?.bringSubviewToFront(self)
    super.touchesBegan(touches, with: event)
    adjustShadow(highlighted: true, animationDuration: Constants.showAnimationDuration)
  }
  
  override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    adjustShadow(highlighted: false, animationDuration: Constants.hideAnimationDuration)
  }
  
  override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    adjustShadow(highlighted: false, animationDuration: Constants.hideAnimationDuration)
  }
  
  // MARK: - Shadow
  
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
  
  private func adjustShadow(highlighted: Bool, animationDuration duration: TimeInterval) {
    
    let group = CAAnimationGroup()
    group.duration = duration
    group.animations = [
      shadowRadiusAnimationWith(highlighted: highlighted),
      shadowOpacityAnimationWith(highlighted: highlighted)
    ]
    layer.add(group, forKey: "shadowAnimations")
    
    layer.shadowRadius = Constants.Shadow.Default.radius
    layer.shadowOpacity = Constants.Shadow.Default.opacity
    
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
      UIView.animate(withDuration: Constants.showAnimationDuration, animations: updateBackgroundColor)
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
