import RxCocoa
import RxSwift
import UIKit
import ZSAPI
import ZSLib
import ZSPrelude

internal final class ProductEditionComponent: UIViewController {
  let viewModel: ProductEditionComponentViewModelType = ProductEditionComponentViewModel()
  private let disposeBag = DisposeBag()

  private let filePicker = FilePicker(modes: [.image, .video])

  internal enum Callback {
    case save(EditProduct)
  }
  internal var callback: ((Callback) -> Void)?

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var nameStackView: UIStackView!
  @IBOutlet weak var name: EditableLabel!
  @IBOutlet weak var priceStackView: UIStackView!
  @IBOutlet weak var price: EditableLabel!
  @IBOutlet weak var descStackView: UIStackView!
  @IBOutlet weak var desc: EditableLabel!
  @IBOutlet weak var stockStackView: UIStackView!
  @IBOutlet weak var stock: EditableStockView!
  @IBOutlet weak var editPicturesStackView: UIStackView!
  @IBOutlet weak var onlineStackView: UIStackView!
  @IBOutlet weak var onlineIcon: UIImageView!
  @IBOutlet weak var online: UILabel!
  @IBOutlet weak var onlineSwitch: UISwitch!

  let editPicturesCarousel = EditPicturesCarousel()

  // MARK: - Init

  internal static func configuredWith(shop: Shop, editProduct: EditProduct) -> ProductEditionComponent {
    let vc = Storyboard.ProductEditionComponent.instantiate(ProductEditionComponent.self)
    vc.configureWith(shop: shop, editProduct: editProduct)
    vc.filePicker.hostViewController = vc
    return vc
  }

  convenience init() {
    self.init(nibName: nil, bundle: nil)
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  // MARK: - Configuration

  internal func configureWith(shop: Shop, editProduct: EditProduct) {
    viewModel.inputs.configureWith(shop: shop, editProduct: editProduct)
  }

  // MARK: - UIViewController

  override func viewDidLoad() {
    super.viewDidLoad()

    stackView.do {
      $0.axis = .vertical
      $0.distribution = .fill
      $0.layoutMargins = .init(top: 20, left: 0, bottom: 0, right: 0)
      $0.isLayoutMarginsRelativeArrangement = true
    }

    let stackViews: [UIStackView] = [
      nameStackView,
      descStackView,
      priceStackView,
      stockStackView,
      onlineStackView
    ]

    stackViews.forEach {
      $0.layoutMargins = .init(top: 0, left: 10, bottom: 0, right: 10)
      $0.isLayoutMarginsRelativeArrangement = true
    }

    let editableViews: [TappableView] = [name, price, desc, stock]
    editableViews.forEach {
      $0.layer.cornerRadius = 5.0
      $0.layer.masksToBounds = false

      $0.backgroundColor(.white, for: .normal)
      $0.backgroundColor(UIColor.white.withBrightnessDelta(-0.04), for: .highlighted)
      $0.padding = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    let editableLabels: [EditableLabel] = [name, price, desc]
    editableLabels.forEach {
      $0.textLabel.textColor = .zs_black
    }

    name.do {
      $0.textLabel.font = .systemFont(ofSize: 40.0, weight: .medium)
      $0.textLabel.numberOfLines = 0
      $0.addTarget(self, action: #selector(namePressed), for: .touchUpInside)
      $0.placeholderText = NSLocalizedString(
        "edit_product.name.placeholder",
        value: "Add the title",
        comment: "Placeholder text on the name field on the product edition view."
      )
    }

    price.do {
      $0.textLabel.font = .systemFont(ofSize: 24.0, weight: .medium)
      $0.addTarget(self, action: #selector(pricePressed), for: .touchUpInside)
      $0.placeholderText = NSLocalizedString(
        "edit_product.price.placeholder",
        value: "Enter the price",
        comment: "Placeholder text on the price field on the product edition view."
      )
    }

    desc.do {
      $0.textLabel.font = .systemFont(ofSize: 24.0, weight: .regular)
      $0.textLabel.numberOfLines = 0
      $0.addTarget(self, action: #selector(descriptionPressed), for: .touchUpInside)
      $0.placeholderText = NSLocalizedString(
        "edit_product.description.placeholder",
        value: "Add a description",
        comment: "Placeholder text on the description field on the product edition view."
      )
    }

    stock.do {
      $0.addTarget(self, action: #selector(stockPressed), for: .touchUpInside)
    }

    online.do {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.backgroundColor = .clear
      $0.font = .systemFont(ofSize: 24.0, weight: .medium)
      $0.numberOfLines = 0
      $0.textColor = .zs_black
      $0.text = NSLocalizedString(
        "edit_product.online",
        value: "Product Online",
        comment: "Label in the online row to edit the online status."
      )
    }

    onlineSwitch.do {
      $0.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    onlineIcon.do {
      $0.image = image(named: "online")
      $0.contentMode = .scaleAspectFit
      $0.backgroundColor = .clear
      $0.tintColor = .zs_black
    }

    scrollView.do {
      $0.alwaysBounceVertical = true
      $0.contentInset = .init(top: 0, left: 0, bottom: 80, right: 0)
      $0.showsHorizontalScrollIndicator = false
    }

    editPicturesCarousel.do {
      $0.delegate = self
      addChild($0)
      editPicturesStackView.addArrangedSubview($0.view)
      $0.didMove(toParent: self)
    }

    // layout
    self.view.setNeedsLayout()
    self.view.layoutIfNeeded()

    viewModel.inputs.viewDidLoad()
  }

  override func bindViewModel() {
    super.bindViewModel()

    viewModel.outputs.name
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.name.text = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.price
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.price.text = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.description
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.desc.text = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.stock
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.stock.configureWith(editStock: $0.2, productId: $0.0, shopId: $0.1)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.online
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.onlineSwitch.isOn = $0
      })
      .disposed(by: disposeBag)

    viewModel.outputs.mode
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        switch $0 {
        case .edition:
          self?.onlineStackView.isHidden = false
        case .review:
          self?.onlineStackView.isHidden = true
        }
      })
      .disposed(by: disposeBag)

    viewModel.outputs.initialPictures
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.editPicturesCarousel.setPictures($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.newPictures
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.editPicturesCarousel.addPictures($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.deletedPictures
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.editPicturesCarousel.deletePictures($0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentNameEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentNameEditionWith(editProduct: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentPriceEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentPriceEditionWith(editProduct: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentDescriptionEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentDescriptionEditionWith(editProduct: $0)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldPresentStockEdition
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.presentStockEditionWith(editStock: $0.editStock, productId: $0.productId, shopId: $0.shopId)
      })
      .disposed(by: disposeBag)

    viewModel.outputs.shouldSubmit
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.callback?(.save($0))
      })
      .disposed(by: disposeBag)

    filePicker.viewModel.outputs.didPickMedias
      .observeOn(AppEnvironment.current.mainScheduler)
      .subscribe(onNext: { [weak self] in
        self?.viewModel.inputs.didAddMedias($0)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Child VCs

  private func presentNameEditionWith(editProduct: EditProduct) {
    let nameEdition =
      ProductEditionName.configuredWith(name: editProduct.name ?? "")
    nameEdition.callback = { [weak self] in
      switch $0 {
      case let .save(name):
        self?.viewModel.inputs.updateName(name)
        nameEdition.dismiss(animated: true, completion: nil)
      }
    }
    self.present(nameEdition, animated: true, completion: nil)
  }

  private func presentPriceEditionWith(editProduct: EditProduct) {
    let priceEdition =
      ProductEditionPrice.configuredWith(priceInfo: editProduct.priceInfo)
    priceEdition.callback = { [weak self] in
      switch $0 {
      case let .save(priceInfo):
        self?.viewModel.inputs.updatePrice(priceInfo)
        priceEdition.dismiss(animated: true, completion: nil)
      }
    }
    self.present(priceEdition, animated: true, completion: nil)
  }

  private func presentDescriptionEditionWith(editProduct: EditProduct) {
    let descEdition =
      ProductEditionDesc.configuredWith(description: editProduct.description ?? "")
    descEdition.callback = { [weak self] in
      switch $0 {
      case let .save(description):
        self?.viewModel.inputs.updateDescription(description)
        descEdition.dismiss(animated: true, completion: nil)
      }
    }
    self.present(descEdition, animated: true, completion: nil)
  }

  private func presentStockEditionWith(editStock: EditStock, productId: String, shopId: String) {
    let stockEdition = ProductEditionStock.configuredWith(
      editStock: editStock,
      productId: productId,
      shopId: shopId
    )

    stockEdition.callback = { [weak self] in
      switch $0 {
      case let .save(editStock):
        self?.viewModel.inputs.updateStock(editStock: editStock)
        stockEdition.dismiss(animated: true, completion: nil)
      }
    }
    self.present(stockEdition, animated: true, completion: nil)
  }

  // MARK: - Events

  @objc internal func namePressed() {
    viewModel.inputs.namePressed()
  }

  @objc internal func pricePressed() {
    viewModel.inputs.pricePressed()
  }

  @objc internal func descriptionPressed() {
    viewModel.inputs.descriptionPressed()
  }

  @objc internal func stockPressed() {
    viewModel.inputs.stockPressed()
  }

  @objc internal func switchChanged(s: UISwitch) {
    viewModel.inputs.updateOnlineState(online: s.isOn)
  }

  // MARK: - Alert
}

extension ProductEditionComponent: EditPicturesCarouselDelegate {
  func editPicturesCarouselDidTapAdd() {
    self.filePicker.viewModel.inputs.addFilesButtonPressed()
  }

  func editPicturesCarouselDidTapPicture(_ picture: EditPicture) {
    let message = NSLocalizedString(
      "product_edition.picture.delete_confirm.title",
      value: "Are you sure you want to delete this media?",
      comment: "Title of alert to confirm if the user wants to delete a media from the product.")

    let deleteActionTitle = NSLocalizedString(
      "product_edition.picture.delete_confirm.delete_title",
      value: "Yes Delete",
      comment: "Title of the button to confirm if the user wants to delete a media from the product.")

    let cancelActionTitle = NSLocalizedString(
      "product_edition.picture.delete_confirm.cancel_title",
      value: "Cancel",
      comment: "Title of the button cancel if the user wants to delete a media from the product.")

    let alert = UIAlertController.confirmationAlert(
      message: message,
      actionTitle: deleteActionTitle,
      cancelTitle: cancelActionTitle) { [weak self] confirm in
        if confirm {
          self?.viewModel.inputs.didDeleteFiles([picture])
        }
    }

    self.navigationController?.present(alert, animated: true, completion: nil)
  }

  func editPicturesCarouselDidReorderPictures(_ pictures: [EditPicture]) {
    self.viewModel.inputs.reorderedPictures(pictures)
  }
}
