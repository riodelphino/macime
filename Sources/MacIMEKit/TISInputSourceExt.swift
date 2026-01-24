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

   private func value(of field: String) -> String {
      switch field {
      case "id": return id
      case "localizedName": return localizedName
      case "isSelectCapable": return "\(isSelectCapable)"
      case "isSelected": return "\(isSelected)"
      case "sourceLanguages": return "\(sourceLanguages)"  // FIX: May causes issue on .json
      default: return ""
      }
   }
   // Return IME fields as specific format
   public func describe(format: OutFormat, fields: [String]) -> Any {
      switch format {
      case .value:
         var lines: [String] = []
         for field in fields {
            lines.append(value(of: field))
         }
         return lines.joined(separator: "\n")
      case .keyValue:
         var lines: [String] = []
         for field in fields {
            lines.append("\(field): \(value(of: field))")
         }
         return lines.joined(separator: "\n")
      case .json:
         var json: [String: Any] = [:]
         for field in fields {
            json[field] = value(of: field)
         }
         return json
      }
   }

}
