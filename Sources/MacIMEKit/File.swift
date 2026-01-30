import Foundation

// File system operations
public enum FS {
   public static func createDir(_ dirPath: String) -> Bool {
      do {
         try FileManager.default.createDirectory(
            atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
      } catch {
         return false
      }
      return true
   }

   public static func removePath(_ path: String) -> Bool {
      do {
         try FileManager.default.removeItem(atPath: path)
      } catch {
         return false
      }
      return true
   }

   public static func pathExists(_ path: String) -> Bool {
      return FileManager.default.fileExists(atPath: path)
   }

   public static func read(_ path: String) -> String? {
      do {
         let content = try String(contentsOfFile: path, encoding: .utf8)
         return content
      } catch {
         return nil
      }
   }

   public static func write(_ path: String, _ content: String) -> Bool {
      do {
         try content.write(toFile: path, atomically: true, encoding: .utf8)
         return true
      } catch {
         return false
      }
   }
}
