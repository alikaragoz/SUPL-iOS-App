import UIKit
import Foundation
import PlaygroundSupport
import ZSLib
import ZSPrelude
import ZShop_Framework

initialize()

let (parent, child) = playgroundControllers(device: .phone5_8inch, orientation: .portrait)
PlaygroundPage.current.liveView = parent

AppEnvironment.replaceCurrentEnvironment(mainBundle: Bundle.framework)

let rootStackView = UIStackView(frame: parent.view.bounds)
rootStackView.alignment = .leading
rootStackView.axis = .vertical
rootStackView.distribution = .fillEqually
rootStackView.isLayoutMarginsRelativeArrangement = true
rootStackView.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
child.view.addSubview(rootStackView)

let rowStackViewStyle: (UIStackView) -> UIStackView = {
    $0.alignment = .top
    $0.axis = .horizontal
    $0.distribution = .equalSpacing
    $0.spacing = 10.0
    return $0
}

///

let rowStackView1 = UIStackView()
rootStackView.addArrangedSubview(rowStackView1)
rowStackView1 |> rowStackViewStyle

let titleButton = FloatButton()
titleButton.translatesAutoresizingMaskIntoConstraints = false
titleButton.setTitle("Title", for: .normal)
titleButton.sizeToFit()
rowStackView1.addArrangedSubview(titleButton)
titleButton |> baseFloatButtonStyle <> greenFloatButtonStyle

///

let rowStackView2 = UIStackView()
rootStackView.addArrangedSubview(rowStackView2)
rowStackView2 |> rowStackViewStyle

let titleButtonDisabled = FloatButton()
titleButtonDisabled.translatesAutoresizingMaskIntoConstraints = false
titleButtonDisabled.setTitle("Disabled", for: .normal)
titleButtonDisabled.sizeToFit()
titleButtonDisabled.isEnabled = false
rowStackView2.addArrangedSubview(titleButtonDisabled)
titleButtonDisabled |> baseFloatButtonStyle <> greenFloatButtonStyle

///

let addImage = image(named: "right-arrow")?.withRenderingMode(.alwaysTemplate)

let rowStackView3 = UIStackView()
rootStackView.addArrangedSubview(rowStackView3)
rowStackView3 |> rowStackViewStyle

let titleAndImageButton = FloatButton()
titleAndImageButton.translatesAutoresizingMaskIntoConstraints = false
titleAndImageButton.setTitle("Title and Icon", for: .normal)
titleAndImageButton.setImage(addImage, for: .normal)
titleAndImageButton.tintColor = .white
titleAndImageButton.sizeToFit()
rowStackView3.addArrangedSubview(titleAndImageButton)
titleAndImageButton
    |> baseFloatButtonStyle
    <> greenFloatButtonStyle
    <> centerTextAndImageFloatButtonStyle

///

let rowStackView4 = UIStackView()
rootStackView.addArrangedSubview(rowStackView4)
rowStackView4 |> rowStackViewStyle

let colorButtonsStyles: [(FloatButton) -> FloatButton] = [
    baseFloatButtonStyle <> greenFloatButtonStyle <> squareFloatButtonStyle,
    baseFloatButtonStyle <> grayFloatButtonStyle <> squareFloatButtonStyle,
    baseFloatButtonStyle <> blackFloatButtonStyle <> squareFloatButtonStyle
]

colorButtonsStyles.forEach { style in
    let button = FloatButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(addImage, for: .normal)
    button.tintColor = .white
    button.sizeToFit()
    rowStackView4.addArrangedSubview(button)
    button |> style
}
