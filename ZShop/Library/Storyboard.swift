import UIKit
import ZSLib

public enum Storyboard: String {
  case EditDescComponent
  case EditNameComponent
  case EditPriceComponent
  case HomeViewController
  case PaypalConnect
  case PaypalWebView
  case ProductCreationPaypal
  case ProductCreationPicture
  case ProductCreationShare
  case ProductEditionComponent
  case ProductEditionStock
  case ProductSaveComponent
  case ShopEdition
  case ShopEditionDomain
  
  public func instantiate<VC: UIViewController>(_ viewController: VC.Type,
                                                inBundle bundle: Bundle = .framework) -> VC {
    guard
      let vc = UIStoryboard(name: self.rawValue, bundle: Bundle(identifier: bundle.identifier))
        .instantiateViewController(withIdentifier: VC.storyboardIdentifier) as? VC
      else {
        fatalError("Couldn't instantiate \(VC.storyboardIdentifier) from \(self.rawValue)")
    }
    
    return vc
  }
}
