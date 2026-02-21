import Darwin
import Foundation

public enum Log {
   private static let isTTY = isatty(STDERR_FILENO) != 0

   private static let formatter: ISO8601DateFormatter = {
      let f = ISO8601DateFormatter()
      f.timeZone = .current
      return f
   }()

   /// Get log level string (Colorize if isTTY)
   private static func getLevelStr(_ logLevel: LogLevel) -> String {
      var levelStr = logLevel.desc
      if isTTY {
         let color = logLevel.color
         levelStr = color.colorize(levelStr)
      }
      return levelStr
   }

   /// Leave a log (to stderr)
   public static func log(_ msg: String, logLevel: LogLevel = .info) {
      guard shouldLog(logLevel) else { return }
      let timestamp = formatter.string(from: Date())
      let logLevelStr = getLevelStr(logLevel)
      let logMsg = "[\(timestamp)] \(logLevelStr) \(msg)\n"
      if let data = logMsg.data(using: .utf8) {
         FileHandle.standardError.write(data) // standardOutput is not appropriate here
      }
   }

   private static func shouldLog(_ level: LogLevel) -> Bool {
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
