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

   /// Get raw value of the field
   private func value(of field: IMEField) -> Any {
      switch field {
      case .id: return id
      case .localizedName: return localizedName
      case .isSelectCapable: return isSelectCapable
      case .isSelected: return isSelected
      case .sourceLanguages: return sourceLanguages
      }
   }

   /// Get value of the field as string
   private func valueStr(of field: IMEField) -> String {
      return String(describing: value(of: field))
   }

   /// Return IME fields as specific format
   func describe(format: OutFormat, fields: [IMEField]) throws -> Any {
      switch format {
      case .text:
         var lines: [String] = []
         for field in fields {
            lines.append(valueStr(of: field))
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
