import Foundation

public enum Util {
   /// Convert JSON to String
   public static func jsonToString(_ data: Any, options: JSONSerialization.WritingOptions) throws -> String {
      let jsonData = try JSONSerialization.data(
         withJSONObject: data,
         options: options
      )
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
         throw AppError.util(.invalidJsonFormat)
      }
      return jsonString
   }

   /// Measure elapsed time
   public static func elapsed(_ block: () throws -> Void) rethrows -> Int {
      let start = DispatchTime.now()
      try block() // `block()` is the swift code block set by the caller
      let end = DispatchTime.now()
      let ms = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
      return Int(ms.rounded())
   }

   /// Return the first existing path in paths
   public static func fallbackPaths(checkPathExists: Bool, paths: [String?]) -> String? {
      for path in paths {
         if checkPathExists {
            if FS.pathExists(path) {
               return path
            }
         } else {
            if let path {
               return path
            }
         }
      }
      return nil
   }

   /// Check if executable or not
   public static func isExecutable(_ path: String, args: [String]?) -> Bool {
      let proc = Process()
      proc.executableURL = URL(fileURLWithPath: path)
      proc.arguments = args ?? []

      do {
         try proc.run()
         proc.waitUntilExit()
         return proc.terminationStatus == 0
      } catch {
         return false
      }
   }
}
