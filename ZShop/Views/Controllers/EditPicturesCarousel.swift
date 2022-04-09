import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

public protocol EditPicturesCarouselDelegate: class {
  func editPicturesCarouselDidTapAdd()
  func editPicturesCarouselDidTapPicture(_ picture: EditPicture)
  func editPicturesCarouselDidReorderPictures(_ pictures: [EditPicture])
}

public final class EditPicturesCarousel: UIViewController {
  let dataSource = EditPicturesCarouselDataSource()
  
  struct Constants {
    static let interItemSpacing: CGFloat = 20
    static let margins: CGFloat = 20
  }
  
  private let layout = PaginationCollectionViewLayout().then {
    $0.itemSize = .zero
    $0.interItemSpacing = Constants.interItemSpacing
    $0.minAlpha = 0.90
    $0.snap = .left
  }
  
  private let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewFlowLayout()).then {
      $0.backgroundColor = .clear
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.showsHorizontalScrollIndicator = false
      $0.decelerationRate = .fast
  }
  
  private var longPressGesture: UILongPressGestureRecognizer!
  internal weak var delegate: EditPicturesCarouselDelegate?
  internal var pictures: [EditPicture] = []
  
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
    
    // collection view
    collectionView.do {
      view.addSubview($0)
      $0.setCollectionViewLayout(layout, animated: false)
      $0.dataSource = dataSource
      $0.delegate = self
      $0.clipsToBounds = false
      
      // recycle
      dataSource.registerClasses(collectionView: $0)
      
      // layout
      $0.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
      $0.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      $0.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      $0.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    dataSource.do {
      $0.delegate = self
    }
    
    longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture)).then {
      $0.minimumPressDuration = 0.25
      collectionView.addGestureRecognizer($0)
    }
    
    // collection view - load
    dataSource.load(pictures: [])
  }
  
  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // setting the size of the items according to the size of the `collectionView` and the aspect ratio
    let refEdgeLength = min(collectionView.bounds.width, collectionView.bounds.height)
    let computedEdgeLength = refEdgeLength - (Constants.margins * 2)
    
    layout.itemSize = self.itemSizeFor(
      aspectRatio: EditPictureCell.Constants.aspectRatio,
      withContainerSize: CGSize(width: computedEdgeLength, height: computedEdgeLength)
    )
    
    self.collectionView.invalidateIntrinsicContentSize()
  }
  
  @objc func handleLongGesture(gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .began:
      guard
        let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView))
        else { break }
      collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
    case .changed:
      let position = gesture.location(in: gesture.view!)
      collectionView.updateInteractiveMovementTargetPosition(position)
    case .ended:
      guard let selectedIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)),
        selectedIndexPath.item < (dataSource.numberOfItems() - 1) else {
          collectionView.cancelInteractiveMovement()
          break
      }
      collectionView.endInteractiveMovement()
    default:
      collectionView.cancelInteractiveMovement()
    }
  }
  
  // MARK: - Data
  
  public func setPictures(_ pictures: [EditPicture]) {
    self.pictures = pictures
    dataSource.load(pictures: pictures)
    reloadWith(animation: true)
  }
  
  public func addPictures(_ pictures: [EditPicture]) {
    self.pictures += pictures
    dataSource.load(pictures: self.pictures)
    let indexToInsertTo = dataSource.numberOfItems() - 1 /* ← AddCell */
    let indexToInsertFrom = indexToInsertTo - pictures.count
    let indexes = (indexToInsertFrom..<indexToInsertTo).map { IndexPath(item: $0, section: 0) }
    insertCellsAt(indexes: indexes)
  }
  
  public func deletePictures(_ pictures: [EditPicture]) {
    let indexes = pictures
      .map { [weak self] in self?.pictures.firstIndex(of: $0) }
      .compactMap { $0 }
      .map { IndexPath(item: $0, section: 0) }
    indexes.forEach { self.pictures.remove(at: $0.item) }
    dataSource.load(pictures: self.pictures)
    deleteCellsAt(indexes: indexes)
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
  
  // MARK: - Selecting
  
  private func moveAt(index: Int) {
    guard index < dataSource.numberOfItems() else {
      trackRuntimeError("index < items.count")
      return
    }
    
    let indexPath = IndexPath(item: index, section: 0)
    self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
  }
  
  private func moveToInsertedPicture() {
    moveAt(index: dataSource.numberOfItems() - 1 - 1 /* ← Add Cell */)
  }
  
  // MARK: - Reload
  
  private func reloadWith(animation animated: Bool) {
    if animated {
      collectionView.performBatchUpdates({
        let indexSet = IndexSet(integersIn: 0...0)
        collectionView.reloadSections(indexSet)
      }, completion: nil)
    } else {
      collectionView.reloadData()
    }
  }
  
  private func insertCellsAt(indexes: [IndexPath]) {
    collectionView.performBatchUpdates({
      collectionView.insertItems(at: indexes)
    }, completion: { _ in
      self.moveToInsertedPicture()
    })
  }
  
  private func deleteCellsAt(indexes: [IndexPath]) {
    collectionView.performBatchUpdates({
      collectionView.deleteItems(at: indexes)
    }, completion: nil)
  }
}

// MARK: - UICollectionViewDelegate

extension EditPicturesCarousel: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    switch indexPath.item {
    case (dataSource.numberOfItems() - 1):
      delegate?.editPicturesCarouselDidTapAdd()
    case 0...(dataSource.numberOfItems() - 2):
      editPicturesCarouselDidTapPictureAt(indexPath: indexPath)
    default:
      return
    }
  }
  
  private func editPicturesCarouselDidTapPictureAt(indexPath: IndexPath) {
    guard let picture = dataSource[indexPath] as? EditPicture else {
      trackRuntimeError("Should be of EditPicture type.")
      return
    }
    delegate?.editPicturesCarouselDidTapPicture(picture)
  }
}

// MARK: - EditPicturesCarouselDataSourceDelegate

extension EditPicturesCarousel: EditPicturesCarouselDataSourceDelegate {
  public func editPicturesCarouselDataSourceDidMoveItemAt(sourceIndex: Int, to destinationIndex: Int) {
    var pictures = self.pictures
    guard destinationIndex < pictures.count else { return }
    
    let editPicture = pictures[sourceIndex]
    pictures.remove(at: sourceIndex)
    pictures.insert(editPicture, at: destinationIndex)
    
    self.pictures = pictures
    dataSource.load(pictures: pictures)
    delegate?.editPicturesCarouselDidReorderPictures(pictures)
  }
}
