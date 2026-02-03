import Foundation

/// Input/Output
public enum IO {
   /// stdout
   public static func out(_ msg: String) {
      Swift.print(msg)
   }

   /// stderr
   public static func err(_ msg: String) {
      if let data = (msg + "\n").data(using: .utf8) {
         FileHandle.standardError.write(data)
      }
   }
}
