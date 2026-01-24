import Foundation

public enum Log {
   // Leave log (to stderr)
   public static func log(_ msg: String) {
      let formatter = ISO8601DateFormatter()
      formatter.timeZone = .current
      let timestamp = formatter.string(from: Date())
      let logMsg = "[\(timestamp)] \(msg)\n"
      if let data = logMsg.data(using: .utf8) {
         FileHandle.standardError.write(data)  // standardOutput is not appropriate here
      }
   }
}
