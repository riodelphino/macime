import InputMethodKit

/// Extend TISInputSource for easy access to the properties
public extension TISInputSource {
   func getProperty(_ key: CFString) -> AnyObject? {
      guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
      return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
   }

   var id: String {
      getProperty(kTISPropertyInputSourceID) as! String
   }

   var localizedName: String {
      getProperty(kTISPropertyLocalizedName) as! String
   }

   var isSelectCapable: Bool {
      getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
   }

   var isSelected: Bool {
      getProperty(kTISPropertyInputSourceIsSelected) as! Bool
   }

   var sourceLanguages: [String] {
      getProperty(kTISPropertyInputSourceLanguages) as? [String] ?? []
   }

   private func value(of field: IMEField) -> Any {
      switch field {
      case .id: return id
      case .localizedName: return localizedName
      case .isSelectCapable: return isSelectCapable
      case .isSelected: return isSelected
      case .sourceLanguages: return sourceLanguages
      }
   }

   /// Return IME fields as specific format
   func describe(format: OutFormat, fields: [IMEField]) throws -> Any {
      switch format {
      case .text:
         var lines: [String] = []
         for field in fields {
            let value = value(of: field)
            lines.append(String(describing: value))
         }
         return lines.joined(separator: "\n")
      case .json:
         var json: [String: Any] = [:]
         for field in fields {
            json[field.rawValue] = value(of: field)
         }
         return json
      }
   }
}
