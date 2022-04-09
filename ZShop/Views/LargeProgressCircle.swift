import RxCocoa
import RxSwift
import UIKit
import ZSLib
import ZSPrelude

public final class LargeProgressCircle: UIControl {
  private let viewModel: LargeProgressCircleViewModelType = LargeProgressCircleViewModel()
  private let disposeBag = DisposeBag()
  
  struct Constants {
    struct Animation {
      static let timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
      static let slowProgressDuration: Double = 60.0
    }

    struct Stroke {
      static let width: CGFloat = 12
    }
  }

  private let constructionLabel = UILabel().then {
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.font = .systemFont(ofSize: 54)
    $0.backgroundColor = .clear
    $0.textColor = .zs_black
    $0.text = "🏗"
  }

  private let circlePlaceholderPathLayer = CAShapeLayer()
  private let circleProgressPathLayer = CAShapeLayer()
  private let checkMarkPathLayer = CAShapeLayer()

  var percentage: Double = 0 {
    didSet {
      viewModel.inputs.setProgressionTo(percent: percentage)
    }
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
    backgroundColor = .white
    
    circlePlaceholderPathLayer.do {
      $0.frame = bounds
      $0.lineWidth = Constants.Stroke.width
      $0.lineCap = .round
      $0.fillColor = UIColor.clear.cgColor
      $0.strokeColor = UIColor.hex(0xEDEDED).cgColor
      $0.strokeEnd = 1.0
      layer.addSublayer($0)
    }
    
    circleProgressPathLayer.do {
      $0.frame = bounds
      $0.lineWidth = Constants.Stroke.width
      $0.lineCap = .round
      $0.fillColor = UIColor.clear.cgColor
      $0.strokeColor = UIColor.zs_green.cgColor
      $0.strokeEnd = 0
      layer.addSublayer($0)
    }
    
    checkMarkPathLayer.do {
      $0.lineWidth = Constants.Stroke.width
      $0.lineCap = .round
      $0.lineJoin = .round
      $0.fillColor = UIColor.clear.cgColor
      $0.strokeColor = UIColor.zs_green.cgColor
      $0.strokeEnd = 0
      layer.addSublayer($0)
    }

    constructionLabel.do {
      addSubview($0)
      $0.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
      $0.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
  }

  public override func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.setProgressionPercentage
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.setPercent($0, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldFinish
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.constructionLabel.isHidden = $0
        self?.setCheckMarkVisibility($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldStartSlowProgress
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] _ in
        self?.startSlowProgressAnimation()
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - Layout
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    
    circlePlaceholderPathLayer.frame = bounds
    circleProgressPathLayer.frame = bounds
    checkMarkPathLayer.frame = bounds
    
    let frame = CGRect(
      x: Constants.Stroke.width / 2,
      y: Constants.Stroke.width / 2,
      width: bounds.size.width - Constants.Stroke.width,
      height: bounds.size.height - Constants.Stroke.width
    )
    
    circlePlaceholderPathLayer.path = circlePathWith(frame: frame).cgPath
    circleProgressPathLayer.path = circlePathWith(frame: frame).cgPath
    checkMarkPathLayer.path = checkMarkPath().cgPath
  }
  
  // MARK: - Paths
  
  func circlePathWith(frame: CGRect) -> UIBezierPath {
    let center = CGPoint(
      x: frame.midX,
      y: frame.midY
    )
    
    let startAngle: CGFloat = -.pi / 2
    let endAngle: CGFloat = startAngle + 2 * .pi
    return UIBezierPath(
      arcCenter: center,
      radius: frame.size.width / 2,
      startAngle: startAngle,
      endAngle: endAngle,
      clockwise: true
    )
  }
  
  func checkMarkPath() -> UIBezierPath {
    return UIBezierPath().then {
      $0.move(to: .init(x: 50.5, y: 101.5))
      $0.addLine(to: .init(x: 84.5, y: 136.5))
      $0.addLine(to: .init(x: 148.5, y: 73.5))
    }
  }
  
  // MARK: - Animate

  public func startSlowProgress() {
    self.viewModel.inputs.startSlowProgress()
  }

  private func startSlowProgressAnimation() {
    CATransaction.begin()
    CATransaction.setAnimationDuration(Constants.Animation.slowProgressDuration)
    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
    self.circleProgressPathLayer.strokeEnd = CGFloat(1)
    CATransaction.commit()
  }
  
  private func setPercent(_ percent: Double, animated: Bool = true, completion: (() -> Void)? = nil) {
    if animated {

      let presentationLayer = circleProgressPathLayer.presentation()
      circleProgressPathLayer.strokeEnd = presentationLayer?.strokeEnd ?? CGFloat(percent)
      self.circleProgressPathLayer.removeAllAnimations()

      CATransaction.begin()
      CATransaction.setAnimationDuration(0.5)
      CATransaction.setAnimationTimingFunction(Constants.Animation.timingFunction)
      self.circleProgressPathLayer.strokeEnd = CGFloat(percent)
      CATransaction.setCompletionBlock {
        completion?()
      }
      CATransaction.commit()
    } else {
      self.circleProgressPathLayer.strokeEnd = CGFloat(percent)
    }
  }
  
  private func setCheckMarkVisibility(_ visible: Bool) {
    UIView.animate(
      withDuration: 4.0,
      delay: 0,
      usingSpringWithDamping: 1.0,
      initialSpringVelocity: 1.0,
      options: .curveEaseOut,
      animations: {
        self.checkMarkPathLayer.strokeEnd = visible ? 1 : 0
    }, completion: nil)
  }
}
