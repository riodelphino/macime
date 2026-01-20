import InputMethodKit

// Extend TISInputSource for easy access to the properties
extension TISInputSource {
   public func getProperty(_ key: CFString) -> AnyObject? {
      guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
      return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
   }
   public var id: String {
      getProperty(kTISPropertyInputSourceID) as! String
   }
   public var localizedName: String {
      getProperty(kTISPropertyLocalizedName) as! String
   }
   public var isSelectCapable: Bool {
      getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
   }
   public var isSelected: Bool {
      getProperty(kTISPropertyInputSourceIsSelected) as! Bool
   }
   public var sourceLanguages: [String] {
      getProperty(kTISPropertyInputSourceLanguages) as? [String] ?? []
   }

   // Return IME info as specific data type
   public var getInfo: (str: String, json: [String: Any]) {  // TODO: Convert jsonToSTring
      var _str = ""
      var _json: [String: Any] = [:]
      _json = [
         "id": id,
         "localizedName": localizedName,
         "isSelectCapable": isSelectCapable,
         "isSelected": isSelected,
         "sourceLanguages": sourceLanguages,
      ]
      _str =
         "id: \(id)\n"
         + "localizedName: \(localizedName)\n"
         + "isSelectCapable: \(isSelectCapable)\n"
         + "isSelected: \(isSelected)\n"
         + "sourceLanguages: \(sourceLanguages)\n"
      return (_str, _json)
   }
}
