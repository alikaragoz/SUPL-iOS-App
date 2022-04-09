extension Data {

  // returns the CGSize of the underliying image stored in the Data
  public var imageSize: CGSize? {
    guard let source: CGImageSource = CGImageSourceCreateWithData(self as CFData, nil) else {
      trackRuntimeError("Couldn't create CGImageSource from data")
      return nil
    }

    guard
      let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [AnyHashable: Any] else {
        trackRuntimeError("Couldn't get metadata from source")
        return nil
    }

    guard
      let width = metadata["PixelWidth"] as? Int,
      let height = metadata["PixelHeight"] as? Int else {
        trackRuntimeError("Couldn't get size information from metadata")
        return nil
    }

    return CGSize(width: width, height: height)
  }
}
