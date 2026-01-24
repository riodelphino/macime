import Foundation

public enum Util {

   // Convert JSON to String
   public static func jsonToString(_ data: Any) throws -> String {
      let jsonData = try JSONSerialization.data(
         withJSONObject: data,
         options: .prettyPrinted
      )
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
         throw AppError.util(.invalidJsonFormat)
      }
      return jsonString
   }

   // Measure elapsed time
   public static func elapsed(_ block: () throws -> Void) rethrows -> Int {
      let start = DispatchTime.now()
      try block()  // `block()` is the swift code block set by the caller
      let end = DispatchTime.now()
      let ms = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
      return Int(ms.rounded())
   }
}
