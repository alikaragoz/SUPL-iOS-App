import UIKit
import ZSAPI
import ZSLib
import ZSPrelude
import RxSwift

public protocol ProductsCarouselDelegate: class {
  func productsCarouselDidTapAdd()
  func productsCarouselDidTapProductWithUrl(_ url: URL?)
  func productsCarouselDidTapEditProduct(_ product: Product)
  func productsCarouselDidTapPreviewWithURL(_ url: URL?)
  func productsCarouselDidTapShareWithURL(_ url: URL?)
  func productsCarouselDidFocusOnProduct(_ product: Product?)
}

public final class ProductsCarousel: UIViewController {
  private let viewModel: ProductsCarouselViewModelType = ProductsCarouselViewModel()
  private let disposeBag = DisposeBag()

  let dataSource = ProductsCarouselDataSource()

  struct Constants {
    static let interItemSpacing: CGFloat = 20
    static let margins: CGFloat = 10
  }

  private let layout = PaginationCollectionViewLayout().then {
    $0.itemSize = .zero
    $0.interItemSpacing = Constants.interItemSpacing
    $0.minScale = 0.98
    $0.minAlpha = 0.75
    $0.verticalAlignment = .top
  }

  private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init()).then {
    $0.backgroundColor = .clear
    $0.clipsToBounds = false
    $0.translatesAutoresizingMaskIntoConstraints = false
    $0.showsHorizontalScrollIndicator = false
    $0.decelerationRate = .fast
  }

  internal weak var delegate: ProductsCarouselDelegate?

  // MARK: - Init

  convenience init() {
    self.init(nibName: nil, bundle: nil)
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: - UIViewController

  override public func viewDidLoad() {
    super.viewDidLoad()

    layout.do {
      $0.delegate = self
    }

    collectionView.do {
      view.addSubview($0)
      $0.setCollectionViewLayout(layout, animated: false)
      $0.dataSource = dataSource
      $0.delegate = self

      // recycle
      dataSource.registerClasses(collectionView: $0)

      // layout
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    // collection view - load
    dataSource.carousel = self
    dataSource.load(products: [])

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()
  }

  override public func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.shouldCallDidTapPreviewDelegate
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.delegate?.productsCarouselDidTapPreviewWithURL($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldCallDidTapShareDelegate
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.delegate?.productsCarouselDidTapShareWithURL($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldCallDidTapProductDelegate
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.delegate?.productsCarouselDidTapProductWithUrl($0)
      })
      .disposed(by: disposeBag)
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // setting the size of the items according to the size of the `collectionView` and the aspect ratio
    let refEdgeLength = min(collectionView.bounds.width, collectionView.bounds.height)
    let computedEdgeLength = refEdgeLength - (Constants.margins * 2)

    layout.itemSize = self.itemSizeFor(
      aspectRatio: ProductCell.Constants.ratio,
      withContainerSize: CGSize(width: computedEdgeLength, height: computedEdgeLength)
    )
    collectionView.invalidateIntrinsicContentSize()
  }

  // MARK: - Data

  public func setProducts(_ products: [Product]) {
    dataSource.load(products: products)
    collectionView.reloadData()
  }

  public func addProduct(products: [Product], index: Int) {
    dataSource.load(products: products)
    insertCellAt(index: IndexPath(item: index, section: 0))
  }

  public func editProduct(products: [Product], index: Int) {
    dataSource.load(products: products)
    reloadCellsAt(indexes: [IndexPath(item: index, section: 0)])
  }

  public func deleteProduct(products: [Product], index: Int) {
    dataSource.load(products: products)
    removeCellAt(index: IndexPath(item: index, section: 0))
  }

  // MARK: - Layout

  private func itemSizeFor(aspectRatio: CGFloat, withContainerSize containerSize: CGSize) -> CGSize {
    if (containerSize.height * aspectRatio) > containerSize.width {
      let tmpHeight = round(containerSize.width / aspectRatio )
      let tmpWidth = ceil(tmpHeight * aspectRatio)
      return CGSize(width: tmpWidth, height: tmpHeight)
    } else {
      return CGSize(width: containerSize.height * aspectRatio, height: containerSize.height)
    }
  }

  func estimatedSize() -> CGSize {
    let refEdgeLength = min(collectionView.bounds.width, collectionView.bounds.height)
    let computedEdgeLength = refEdgeLength - (Constants.margins * 2)

    let size = self.itemSizeFor(
      aspectRatio: ProductCell.Constants.ratio,
      withContainerSize: CGSize(width: computedEdgeLength, height: computedEdgeLength)
    )
    return .init(width: size.width, height: size.height + 100)
  }

  // MARK: - Selecting

  private func moveAt(index: Int) {
    guard index < dataSource.numberOfItems() else {
      trackRuntimeError("index < items.count")
      return
    }

    let indexPath = IndexPath(item: index, section: 0)
    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    pagniationCollectionViewLayoutDidMoveScroll(atIndexPath: indexPath)
  }

  func moveToCurrentProduct() {
    if self.dataSource.numberOfItems() > 1 { // 1: because we have a static cell
      moveAt(index: dataSource.numberOfItems() - 1 - 1 /* ← AddCell */)
    }
  }

  // MARK: - Reload

  private func insertCellAt(index: IndexPath) {
    collectionView.performBatchUpdates({
      collectionView.insertItems(at: [index])
    }, completion: { _ in
      self.moveToCurrentProduct()
    })
  }

  private func removeCellAt(index: IndexPath) {
    collectionView.performBatchUpdates({
      collectionView.deleteItems(at: [index])
    })
  }

  private func reloadCellsAt(indexes: [IndexPath]) {
    collectionView.performBatchUpdates({
      collectionView.reloadItems(at: indexes)
    }, completion: { _ in
      if let index = indexes.first?.item {
        self.moveAt(index: index)
      }
    })
  }
}

// MARK: - UICollectionViewDelegate

extension ProductsCarousel: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    switch indexPath.item {
    case dataSource.numberOfItems() - 1:
      delegate?.productsCarouselDidTapAdd()
    case 0...(dataSource.numberOfItems() - 2):
      productsCarouselDidTapProductWithUrlAt(indexPath: indexPath)
    default:
      return
    }
  }

  private func productsCarouselDidTapProductWithUrlAt(indexPath: IndexPath) {
    guard let product = dataSource[indexPath] as? Product else {
      trackRuntimeError("Should be of Product type.")
      return
    }
    viewModel.inputs.productCellDidTapProduct(product)
  }
}

// MARK: - ProductAddCellDelegate

extension ProductsCarousel: ProductAddCellDelegate {
  public func productAddCelldidTap() {
    self.delegate?.productsCarouselDidTapAdd()
  }
}

// MARK: - ProductCellDelegate

extension ProductsCarousel: ProductCellDelegate {
  public func productCellDidTapEditButton(product: Product) {
    delegate?.productsCarouselDidTapEditProduct(product)
  }

  public func productCellDidTapShareButton(product: Product) {
    viewModel.inputs.productCellDidTapShareButton(product)
  }

  public func productCellDidTapPreviewButton(product: Product) {
    viewModel.inputs.productCellDidTapPreviewButton(product)
  }
}

// MARK: - PaginationCollectionViewLayoutDelegate

extension ProductsCarousel: PaginationCollectionViewLayoutDelegate {
  public func pagniationCollectionViewLayoutDidMoveScroll(atIndexPath indexPath: IndexPath) {
    var product: Product?
    if let p = dataSource[indexPath] as? Product {
      product = p
    }
    delegate?.productsCarouselDidFocusOnProduct(product)
  }
}
