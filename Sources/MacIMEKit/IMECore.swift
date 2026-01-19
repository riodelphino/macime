import Foundation
import InputMethodKit

public struct IMECore {
   public static var sources: [TISInputSource] {
      let sourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
      return sourceNSArray as! [TISInputSource]
   }

   public static func select(id: String) throws -> TISInputSource {
      guard let source = sources.first(where: { $0.id == id }) else {
         throw AppError.notFound(id)
      }
      let ret = TISSelectInputSource(source)

      if ret != 0 {
         throw AppError.selectFailed(id, ret)
      }
      return source
   }

   public static func current() throws -> TISInputSource? {
      guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
         throw AppError.getCurrentFailed
      }
      return source
   }

   public static func list(selectCapable: Bool) -> [TISInputSource] {
      if selectCapable {
         return sources.filter(\.isSelectCapable)
      } else {
         return sources
      }
   }

   public static func previous(session_id: String?) -> String? {
      let path = getStoredPath(session_id)
      let prev_id = File.read(path)
      return prev_id
   }

   public static func getStoredPath(_ sessionID: String?) -> String {
      let basename = sessionID ?? "DEFAULT"
      return config.tempDir + "/" + basename
   }

   public static func ensureTempDirExists() throws {
      if !File.pathExists(config.tempDir) {
         guard File.createDir(config.tempDir) else {
            throw AppError.createTempDirFailed(config.tempDir)
         }
      }
   }
}
