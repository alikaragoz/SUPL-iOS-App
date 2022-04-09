public class BackwardDetectableTextField: UITextField {

  public enum Callback {
    case deleteBackward
  }
  public var callback: ((Callback) -> Void)?

  public override func deleteBackward() {
    super.deleteBackward()
    callback?(.deleteBackward)
  }
}
