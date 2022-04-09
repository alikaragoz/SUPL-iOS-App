import UIKit

public final class PaginationCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
  public var decorationPercent: CGFloat = 0.0

  public override func copy(with zone: NSZone? = nil) -> Any {
    guard let copy = super.copy(with: zone) as? PaginationCollectionViewLayoutAttributes else {
      return UICollectionViewLayoutAttributes()
    }
    copy.decorationPercent = self.decorationPercent
    return copy
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let layoutAttributes = object as? PaginationCollectionViewLayoutAttributes else {
      return super.isEqual(object)
    }
    return super.isEqual(layoutAttributes) && (layoutAttributes.decorationPercent == self.decorationPercent)
  }
}

public protocol PaginationCollectionViewLayoutDelegate: class {
  func pagniationCollectionViewLayoutDidMoveScroll(atIndexPath indexPath: IndexPath)
}

public final class PaginationCollectionViewLayout: UICollectionViewLayout {

  public enum VerticalAlignment {
    case top
    case center
    case bottom
  }

  public enum Snap {
    case left
    case center
  }

  // MARK: - Public Properties

  public var itemSize: CGSize = .zero {
    didSet {
      self.invalidateLayout()
    }
  }

  public var verticalAlignment: VerticalAlignment = .center
  public var snap: Snap = .center
  public var interItemSpacing: CGFloat = 0
  public var minScale: CGFloat = 1.0
  public var minAlpha: CGFloat = 1.0

  public weak var delegate: PaginationCollectionViewLayoutDelegate?

  // MARK: - Private Properties

  private var contentSize: CGRect = .zero
  private var contentStart: CGPoint = .zero

  public override func prepare() {
    super.prepare()
    self.calculateLayoutProperties()
  }

  public override var collectionViewContentSize: CGSize {
    return self.contentSize.size
  }

  // MARK: - Attributes

  public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let collectionView = self.collectionView else { return nil }

    let combinedItemWidth = self.itemSize.width + self.interItemSpacing

    guard combinedItemWidth > 0 else { return nil }

    let minXPosition = rect.minX - self.contentStart.x
    let maxXPosition = rect.maxX - self.contentStart.x

    let firstVisibleItemIndex = Int(max(floor(minXPosition / combinedItemWidth), 0))
    let lastVisibleItemIndex = Int(
      min(ceil(maxXPosition / combinedItemWidth), CGFloat(collectionView.numberOfItems(inSection: 0)))
    )

    var attributes = [UICollectionViewLayoutAttributes]()

    if lastVisibleItemIndex > firstVisibleItemIndex {
      for i in (firstVisibleItemIndex..<lastVisibleItemIndex) {
        let indexPath = IndexPath(item: i, section: 0)
        guard let layoutAttributes = self.layoutAttributesForItem(at: indexPath) else { continue }
        attributes.append(layoutAttributes)
      }
    }

    return attributes
  }

  public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    let attributes = PaginationCollectionViewLayoutAttributes(forCellWith: indexPath)

    // Bounds
    attributes.bounds = CGRect(origin: .zero, size: self.itemSize)

    // Center
    attributes.center = self.centerForItemAtIndexPath(indexPath)

    // Percent
    let scale = self.percentForAttributes(attributes, offset: 200, minValue: minScale)
    attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
    attributes.alpha = self.percentForAttributes(attributes, offset: 200, minValue: minAlpha)

    // Decoration Percent
    let decorationPercent = self.percentForAttributes(attributes, offset: 35, minValue: 0)
    attributes.decorationPercent = sqrt(decorationPercent)

    return attributes
  }

  // MARK: - Layout Computations

  private func calculateLayoutProperties() {
    guard let collectionView = self.collectionView else { return }

    let horizontalMargin: CGFloat
    switch self.snap {
    case .left:
      horizontalMargin = self.interItemSpacing
    case .center:
      horizontalMargin = (collectionView.bounds.size.width - self.itemSize.width) / 2
    }

    let verticalMargin = (collectionView.bounds.size.height - self.itemSize.height) / 2
    let numberOfItems = collectionView.numberOfItems(inSection: 0)

    let contentWidth = (CGFloat(numberOfItems) * self.itemSize.width)
      + (CGFloat(numberOfItems - 1) * self.interItemSpacing)
      + (2 * horizontalMargin)
    let contentHeight = self.itemSize.height + 2 * verticalMargin
    let contentRect = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)

    var y = contentRect.midY + collectionView.contentInset.top
    switch self.verticalAlignment {
    case .top:
      y -= verticalMargin
    case .center:
      break
    case .bottom:
      y += verticalMargin
    }

    self.contentSize = contentRect.inset(by: collectionView.contentInset)
    self.contentStart = CGPoint(x: horizontalMargin, y: y)
  }

  private func centerForItemAtIndexPath(_ indexPath: IndexPath) -> CGPoint {
    let x = self.contentStart.x
      + (CGFloat(indexPath.row) * (self.itemSize.width + self.interItemSpacing))
      + (self.itemSize.width / 2)
    return CGPoint(x: x, y: self.contentStart.y)
  }

  // MARK: - Layout Invalidation

  public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }

  // MARK: - Target Content Offset

  public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                           withScrollingVelocity velocity: CGPoint) -> CGPoint {
    guard let collectionView = self.collectionView,
      let attributes = self.layoutAttributesForItemAtOffset(proposedContentOffset, velocity: velocity) else {
        return .zero
    }
    self.delegate?.pagniationCollectionViewLayoutDidMoveScroll(atIndexPath: attributes.indexPath)
    return CGPoint(x: attributes.center.x - collectionView.bounds.size.width / 2, y: 0)
  }

  private func layoutAttributesForItemAtOffset(
    _ offset: CGPoint,
    velocity: CGPoint = .zero) -> UICollectionViewLayoutAttributes? {
    guard let attributes = self.layoutAttributesForElementsAtContentOffset(offset) else { return nil }

    var layoutAttributes: UICollectionViewLayoutAttributes?

    if velocity.x > 0 {
      layoutAttributes = attributes.last
    } else if velocity.x < 0 {
      layoutAttributes = attributes.first
    } else {
      layoutAttributes = self.closeToCenterLayoutAttributes(attributes)
    }

    return layoutAttributes
  }

  private func layoutAttributesForElementsAtContentOffset(_ offset: CGPoint)
    -> [UICollectionViewLayoutAttributes]? {
      guard let collectionView = self.collectionView else { return nil }
      let rect = CGRect(origin: offset, size: collectionView.bounds.size)
      return self.layoutAttributesForElements(in: rect)
  }

  private func closeToCenterLayoutAttributes(_ attributes: [UICollectionViewLayoutAttributes])
    -> UICollectionViewLayoutAttributes? {
      guard let collectionView = self.collectionView else { return nil }

      var layoutAttributes: UICollectionViewLayoutAttributes?

      var distanceToCenter = CGFloat.greatestFiniteMagnitude
      attributes.forEach({ att in
        let center = collectionView.contentOffset.x + collectionView.frame.midX
        let distance = abs(center - att.center.x)
        if distance < distanceToCenter {
          distanceToCenter = distance
          layoutAttributes = att
        }
      })

      return layoutAttributes
  }
}

extension PaginationCollectionViewLayout {

  func currentIndexPath() -> IndexPath? {
    guard let collectionView = self.collectionView,
      let attributes = self.layoutAttributesForElementsAtContentOffset(collectionView.contentOffset) else {
        return nil
    }
    return self.closeToCenterLayoutAttributes(attributes)?.indexPath
  }

  private func percentForAttributes(_ attributes: UICollectionViewLayoutAttributes,
                                    offset: CGFloat,
                                    minValue: CGFloat) -> CGFloat {
    guard let collectionView = self.collectionView else { return 1 }
    let center = collectionView.contentOffset.x + collectionView.frame.midX
    let distance = center - attributes.center.x
    let absoluteDistance = min(abs(distance), offset)
    let percent = absoluteDistance * (minValue - 1) / offset + 1
    return percent
  }
}
