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
      return Config.tempDir + "/" + basename
   }

   public static func ensureTempDirExists() throws {
      if !File.pathExists(Config.tempDir) {
         guard File.createDir(Config.tempDir) else {
            throw AppError.createTempDirFailed(Config.tempDir)
         }
      }
   }

   public static func execute(_ state: CmdState) -> Response {
      do {

         switch state.subcmd {
         case "save":
            try ensureTempDirExists()
            if let curr = try current() {
               let path = getStoredPath(state.sessionID)
               let success = File.write(path, curr.id)
               guard success else {
                  throw AppError.saveFailed(path)  // FIX: Should treat in IMECore?
               }
               return Response(status: .ok, content: "")
            }
            return Response(status: .err, content: "Cannot get current IME ID.")
         case "load":
            try ensureTempDirExists()
            if let prev_id = previous(session_id: state.sessionID) {
               let _ = try select(id: prev_id)
               return Response(status: .ok, content: "")
            }
            return Response(status: .err, content: "Previous IME ID is not set.")  // FIX: Trigger an MacIMEError?
         case "list":
            var sources: [TISInputSource]
            var outJson: [Any] = []
            var outStr: [String] = []
            sources = list(selectCapable: state.selectCapable)
            if state.detail {
               if state.json {
                  // list detail as json
                  for source in sources {
                     outJson.append(source.getInfo.json)
                  }
                  return Response(status: .ok, content: try Util.jsonToString(outJson))
               } else {
                  // list detail as str
                  for source in sources {
                     outStr.append(source.getInfo.str)
                  }
                  return Response(status: .ok, content: outStr.joined(separator: "\n"))
               }
            } else {
               if state.json {
                  // list id as json
                  for source in sources {
                     outJson.append(source.id)
                  }
                  return Response(status: .ok, content: try Util.jsonToString(outJson))
               } else {
                  // list id as str
                  for source in sources {
                     outStr.append(source.id)
                  }
                  return Response(status: .ok, content: outStr.joined(separator: "\n"))
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
                        throw AppError.saveFailed(path)  // FIX: Shold handle this internally instead of propagating it to the outside?
                     }
                     return Response(status: .ok, content: "")
                  }
               }
            }
         case "get":
            if let curr = try current() {
               if state.detail {
                  if state.json {
                     // curr IME detail as JSON
                     return Response(status: .ok, content: try Util.jsonToString(curr.getInfo.json))
                  } else {
                     // curr IME detail as string
                     return Response(status: .ok, content: curr.getInfo.str)
                  }
               } else {
                  if state.json {
                     // curr IME id as JSON
                     return Response(status: .ok, content: try Util.jsonToString(curr.id))
                  } else {
                     // curr IME id as string
                     return Response(status: .ok, content: curr.id)
                  }
               }
            }
         default:
            return Response(
               status: .err, content: "Invalid Sub-command: \(state.subcmd ?? "UNKNOWN")")
         }
      } catch let e as AppError {
         switch e {
         case .notFound(let id):
            return Response(status: .err, content: "IME not found: '\(id)'")
         case .selectFailed(let id, let osstatus):
            return Response(
               status: .err, content: "IME switch failed: '\(id)' (\(String(osstatus)))")
         case .getCurrentFailed:
            return Response(status: .err, content: "Cannot get current IME")
         case .createTempDirFailed(let dir):
            return Response(status: .err, content: "Cannot create temp directory: '\(dir)'")
         case .jsonSerializationFailed(let msg):
            return Response(status: .err, content: "Serializing JSON failed: \(msg)")
         default:
            return Response(status: .err, content: "Unhandled error: \(e)")
         }
      } catch {
         return Response(status: .err, content: "Unexpected error: \(error)")
      }
      return Response(status: .err, content: "")  // FIX: How to remove this?
   }
}
