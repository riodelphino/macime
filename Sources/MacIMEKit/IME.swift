import Foundation
import InputMethodKit

public struct IME {
   // Lazy load
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
      guard let prev_id = File.read(path) else {
         throw AppError.ime(.previousIDNotFound)
      }
      return prev_id  // return IME ID as String for performance
   }

   public static func getStoredPath(_ sessionID: String?) -> String {
      let basename = sessionID ?? "DEFAULT"
      return Config.tempDir + "/" + basename
   }

   public static func createTempDir() throws {
      if !File.pathExists(Config.tempDir) {
         guard File.createDir(Config.tempDir) else {
            throw AppError.ime(.createDirFailed(Config.tempDir))
         }
      }
   }

   public static func execute(_ state: IMECmdState) throws -> String {
      let detail: [String] = [
         "id", "localizedName", "isSelectCapable", "isSelected", "sourceLanguages",
      ]
      // IO.out(state.subcmd ?? "?")  // DEBUG:

      switch state.subcmd {
      case "save":
         try createTempDir()
         if let curr = try current() {
            let path = getStoredPath(state.sessionID)
            let success = File.write(path, curr.id)
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
         var outJson: [Any] = []
         var outStr: [String] = []
         sources = list(selectCapable: state.selectCapable)
         if state.detail {
            if state.json {
               // list detail as json
               for source in sources {
                  outJson.append(source.describe(format: .json, fields: detail))
               }
               return try Util.jsonToString(outJson)
            } else {
               // list detail as str
               for source in sources {
                  outStr.append("\(source.describe(format: .keyValue, fields: detail))")
               }
               return outStr.joined(separator: "\n")
            }
         } else {
            if state.json {
               // list id as json
               for source in sources {
                  outJson.append(source.id)
               }
               return try Util.jsonToString(outJson)
            } else {
               // list id as str
               for source in sources {
                  outStr.append(source.id)
               }
               return outStr.joined(separator: "\n")
            }
         }
      case "set":
         // Switch to new ID
         if let curr = try current() {
            let currID = curr.id  // Need to save here
            if let _newID = state.newID {
               let _ = try select(id: _newID)
               // Save to /tmp
               if state.save {
                  let path = getStoredPath(state.sessionID)
                  let success = File.write(path, currID)
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
               if state.json {
                  // curr IME detail as JSON
                  let outJson: Any = curr.describe(format: .json, fields: detail)
                  return try Util.jsonToString(outJson)
               } else {
                  // curr IME detail as string
                  let outStr: String =
                     "\(curr.describe(format: .keyValue, fields: detail))"
                  return outStr
               }
            } else {
               if state.json {
                  // curr IME id as JSON
                  return try Util.jsonToString(curr.id)
               } else {
                  // curr IME id as string
                  return curr.id
               }
            }
         }
      default:
         throw AppError.ime(.invalidSubCommand(state.subcmd ?? "Unknown"))
      }
      throw AppError.ime(.invalidSubCommand("Unknown"))
   }
}
