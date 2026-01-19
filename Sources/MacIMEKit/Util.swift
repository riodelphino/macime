import Foundation

// Utilities
public enum Util {
   public static func jsonToString(_ data: Any) throws -> String {
      let jsonData = try JSONSerialization.data(
         withJSONObject: data,
         options: .prettyPrinted
      )
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
         throw AppError.loadFailed("Invalid UTF-8 JSON")
      }
      return jsonString
   }
}
