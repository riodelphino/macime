import Foundation

public enum Log {
   /// Leave log (to stderr)
   public static func log(_ msg: String, logLevel: LogLevel = .info) {
      guard shouldLog(logLevel) else { return }
      let formatter = ISO8601DateFormatter()
      formatter.timeZone = .current
      let timestamp = formatter.string(from: Date())
      let logMsg = "[\(timestamp)] \(msg)\n"
      if let data = logMsg.data(using: .utf8) {
         FileHandle.standardError.write(data) // standardOutput is not appropriate here
      }
   }

   public static func getLogLevelByString(_ level: String) -> LogLevel {
      switch level {
      case "debug":
         return .debug
      case "info":
         return .info
      case "warn":
         return .warn
      case "error":
         return .error
      default:
         IO.err("Invalid log level: \(level) (Choose from debug|info|warn|error)") // TODO: Should be AppError?
         exit(1)
      }
   }

   public static func shouldLog(_ level: LogLevel) -> Bool {
      return level >= Runtime.logLevel
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
