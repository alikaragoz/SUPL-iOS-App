import RxCocoa
import RxSwift
import UIKit
import ZSLib
import ZSPrelude

public final class ProgressLine: UIControl {
  let viewModel: ProgressLineViewModelType = ProgressLineViewModel()
  private let disposeBag = DisposeBag()
  
  struct Constants {
    struct Animation {
      static let timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
      static let slowProgressDuration: Double = 15.0
    }

    struct Stroke {
      static let width: CGFloat = 2
    }
  }

  private let lineProgressPathLayer = CAShapeLayer()

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
    backgroundColor = .clear

    lineProgressPathLayer.do {
      $0.frame = bounds
      $0.lineWidth = Constants.Stroke.width
      $0.lineCap = .square
      $0.fillColor = UIColor.clear.cgColor
      $0.strokeColor = UIColor.zs_green.cgColor
      $0.strokeEnd = 0
      layer.addSublayer($0)
    }

    self.setupBindings()
  }

  private func setupBindings() {

    viewModel.outputs.setProgressionPercentage
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.setPercent($0, animated: true, completion: nil)
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
    lineProgressPathLayer.frame = bounds
    lineProgressPathLayer.path = linePathWith(frame: bounds).cgPath
  }
  
  // MARK: - Paths
  
  func linePathWith(frame: CGRect) -> UIBezierPath {
    let path = UIBezierPath()
    path.move(to: CGPoint(x: 0, y: Constants.Stroke.width / 2))
    path.addLine(to: CGPoint(x: frame.maxX, y: Constants.Stroke.width / 2))
    return path
  }
  
  // MARK: - Animate

  public func startSlowProgress() {
    self.viewModel.inputs.startSlowProgress()
  }

  private func startSlowProgressAnimation() {
    CATransaction.begin()
    CATransaction.setAnimationDuration(Constants.Animation.slowProgressDuration)
    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
    self.lineProgressPathLayer.strokeEnd = CGFloat(1)
    CATransaction.commit()
  }
  
  private func setPercent(_ percent: Double, animated: Bool = true, completion: (() -> Void)? = nil) {
    if animated {

      let presentationLayer = lineProgressPathLayer.presentation()
      lineProgressPathLayer.strokeEnd = presentationLayer?.strokeEnd ?? CGFloat(percent)
      self.lineProgressPathLayer.removeAllAnimations()

      CATransaction.begin()
      CATransaction.setAnimationDuration(0.5)
      CATransaction.setAnimationTimingFunction(Constants.Animation.timingFunction)
      self.lineProgressPathLayer.strokeEnd = CGFloat(percent)
      CATransaction.setCompletionBlock {
        completion?()
      }
      CATransaction.commit()
    } else {
      self.lineProgressPathLayer.strokeEnd = CGFloat(percent)
    }
  }
}
