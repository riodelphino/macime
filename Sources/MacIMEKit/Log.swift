import Foundation

public enum LogLevels {
   case debug
   case info
   case warn
   case error
   public var desc: String {
      switch self {
      case .debug:
         return "DEBUG"
      case .info:
         return "INFO "
      case .warn:
         return "WARN "
      case .error:
         return "ERROR "
      }
   }
}

public enum Log {
   /// Leave log (to stderr)
   public static func log(_ msg: String, logLevel _: LogLevels = .info) {
      let formatter = ISO8601DateFormatter()
      formatter.timeZone = .current
      let timestamp = formatter.string(from: Date())
      let logMsg = "[\(timestamp)] \(msg)\n"
      if let data = logMsg.data(using: .utf8) {
         FileHandle.standardError.write(data) // standardOutput is not appropriate here
      }
   }

   public static func debug(_ msg: String) {
      log(msg, logLevel: .debug)
   }

   public static func info(_ msg: String) {
      log(msg, logLevel: .info)
   }

   public static func warn(_ msg: String) {
      log(msg, logLevel: .warn)
   }

   public static func error(_ msg: String) {
      log(msg, logLevel: .error)
   }
}
