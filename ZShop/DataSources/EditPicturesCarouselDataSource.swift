import Foundation
import ZSAPI
import ZSLib

public protocol EditPicturesCarouselDataSourceDelegate: class {
  func editPicturesCarouselDataSourceDidMoveItemAt(sourceIndex: Int, to destinationIndex: Int)
}

internal final class EditPicturesCarouselDataSource: ValueCellDataSource {

  weak var delegate: EditPicturesCarouselDataSourceDelegate?

  internal enum Section: Int {
    case pictures
  }

  internal override func registerClasses(collectionView: UICollectionView?) {
    collectionView?.registerCellClass(EditPictureCell.self)
    collectionView?.registerCellClass(EditVideoCell.self)
    collectionView?.registerCellClass(EditPictureAddCell.self)
  }

  internal func load(pictures: [EditPicture]) {
    self.clearValues()
    for editPicture in pictures {
      if editPicture.kind == Visual.Kind.photo.rawValue {
        self.appendRow(value: editPicture,
                       cellClass: EditPictureCell.self,
                       toSection: Section.pictures.rawValue)
      } else if editPicture.kind == Visual.Kind.cloudflareVideo.rawValue {
        self.appendRow(value: editPicture,
                       cellClass: EditVideoCell.self,
                       toSection: Section.pictures.rawValue)
      }
    }
    self.appendRow(value: (), cellClass: EditPictureAddCell.self, toSection: Section.pictures.rawValue)
  }

  internal override func configureCell(collectionCell cell: UICollectionViewCell, withValue value: Any) {
    switch (cell, value) {
    case let (cell as EditPictureCell, value as EditPicture):
      cell.configureWith(value: value)
    case let (cell as EditVideoCell, value as EditPicture):
      cell.configureWith(value: value)
    case (is StaticCollectionViewCell, is Void):
      return
    default:
      assertionFailure("Unrecognized combo: \(cell), \(value).")
    }
  }

  // MARK: - Drag n Drop

  public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
    return indexPath.item < (self.numberOfItems() - 1)
  }

  public func collectionView(_ collectionView: UICollectionView,
                             moveItemAt sourceIndexPath: IndexPath,
                             to destinationIndexPath: IndexPath) {
    delegate?.editPicturesCarouselDataSourceDidMoveItemAt(
      sourceIndex: sourceIndexPath.item,
      to: destinationIndexPath.item
    )
  }
}
