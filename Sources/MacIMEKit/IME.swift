import Foundation
import InputMethodKit

public enum IME {
   /// Lazy load
   private static var _sources: [TISInputSource]?

   public static var sources: [TISInputSource] {
      if let cached = _sources {
         return cached
      }
      let arr =
         TISCreateInputSourceList(nil, false)
            .takeRetainedValue() as NSArray
      let list = arr as! [TISInputSource]
      _sources = list
      return list
   }

   public static func select(id: String) throws -> TISInputSource {
      guard let source = sources.first(where: { $0.id == id }) else {
         throw AppError.ime(.notFound(id))
      }
      let ret = TISSelectInputSource(source)

      if ret != 0 {
         throw AppError.ime(.selectFailed(id, ret))
      }
      return source
   }

   public static func current() throws -> TISInputSource? {
      guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
         throw AppError.ime(.getCurrentFailed)
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

   public static func previous(session_id: String?) throws -> String {
      let path = getStoredPath(session_id)
      guard let prev_id = FS.read(path) else {
         throw AppError.ime(.previousIDNotFound)
      }
      return prev_id // return IME ID as String for performance
   }

   public static func getStoredPath(_ sessionID: String?) -> String {
      let basename = sessionID ?? "DEFAULT"
      return Defaults.tempDir + "/" + basename
   }

   public static func createTempDir() throws {
      if !FS.pathExists(Defaults.tempDir) {
         guard FS.createDir(Defaults.tempDir) else {
            throw AppError.ime(.createDirFailed(Defaults.tempDir))
         }
      }
   }

   public static func execute(_ state: IMECmdState) throws -> String {
      enum fieldList {
         static let id: [String] = ["id"]
         static let detail: [String] = [
            "id", "localizedName", "isSelectCapable", "isSelected", "sourceLanguages",
         ]
      }

      switch state.subcmd {
      case "save":
         try createTempDir()
         if let curr = try current() {
            let path = getStoredPath(state.sessionID)
            let success = FS.write(path, curr.id)
            guard success else {
               throw AppError.ime(.saveFailed(path))
            }
            return curr.id
         }
      case "load":
         try createTempDir()
         let prev_id = try previous(session_id: state.sessionID)
         let src = try select(id: prev_id)
         return src.id
      case "list":
         var sources: [TISInputSource]
         sources = list(selectCapable: state.selectCapable)
         if state.detail {
            // list detail as json
            var outJson: [Any] = []
            for source in sources {
               try outJson.append(source.describe(format: .json, fields: fieldList.detail))
            }
            return try Util.jsonToString(outJson)
         } else {
            // list IDs as string
            var ids: [String] = []
            for source in sources {
               ids.append(source.id)
            }
            return ids.joined(separator: "\n")
         }
      case "set":
         // Switch to new ID
         if let curr = try current() {
            let currID = curr.id // Need to save here
            if let _newID = state.newID {
               let _ = try select(id: _newID)
               // Save to /tmp
               if state.save {
                  let path = getStoredPath(state.sessionID)
                  let success = FS.write(path, currID)
                  guard success else {
                     throw AppError.ime(.saveFailed(path))
                  }
               }
               return ""
            }
         }
      case "get":
         if let curr = try current() {
            if state.detail {
               // curr IME detail as JSON
               let outJson: Any = try curr.describe(format: .json, fields: fieldList.detail)
               return try Util.jsonToString(outJson)
            } else {
               // curr IME id as string
               return curr.id
            }
         }
      default:
         throw AppError.ime(.invalidSubCommand(state.subcmd ?? "Unknown"))
      }
      throw AppError.ime(.invalidSubCommand("Unknown"))
   }
}
