import Foundation
import InputMethodKit

public enum IME {
   public static var state: IMEState!

   public static func setState(_ newState: IMEState) {
      state = newState
   }

   private static let BASE_IME = "com.apple.keylayout.ABC"

   /// fields list
   private enum fieldsList {
      static let id: [String] = ["id"]
      static let detail: [String] = [
         "id", "localizedName", "isSelectCapable", "isSelected", "sourceLanguages",
      ]
   }

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

   public static func sources(selectCapable: Bool) -> [TISInputSource] {
      if selectCapable {
         return sources.filter(\.isSelectCapable)
      } else {
         return sources
      }
   }

   public static func previous(session_id: String?) throws -> String {
      let path = try getStoredPath(session_id)
      guard let prev_id = FS.read(path) else {
         throw AppError.ime(.previousIDNotFound)
      }
      return prev_id // return IME ID as String for performance
   }

   public static func getStoredPath(_ sessionID: String?) throws -> String {
      let basename = sessionID ?? "GLOBAL"
      return try Defaults.tempDir() + "/" + basename
   }

   public static func createTempDir() throws {
      if try !FS.pathExists(Defaults.tempDir()) {
         guard try FS.createDir(Defaults.tempDir()) else {
            throw try AppError.ime(.createDirFailed(Defaults.tempDir()))
         }
      }
   }

   /// save sub-command
   public static func save(_ state: IMEState) throws -> String {
      try createTempDir()
      guard let curr = try current() else {
         throw AppError.ime(.getCurrentFailed)
      }
      let path = try getStoredPath(state.sessionID)
      let success = FS.write(path, curr.id)
      guard success else {
         throw AppError.ime(.saveFailed(path))
      }
      return curr.id
   }

   /// load sub-command
   public static func load(_ state: IMEState) throws -> String {
      try createTempDir()
      let prev_id = try previous(session_id: state.sessionID)

      if state.cjkRefresh {
         _ = try select(id: BASE_IME) // NOTE: Should set it once before setting desired ID (to make IME switching more reliably)
      }

      let src = try select(id: prev_id)
      // NOTE: The CJK IME internal mode has not been switched yet because the change happens asynchronously.

      if state.cjkRefresh { CJK.refresh(desiredID: prev_id) }

      return src.id
   }

   /// list sub-command
   public static func list(_ state: IMEState) throws -> String {
      if state.detail {
         // list detail as json
         var outJson: [Any] = []
         for source in sources(selectCapable: state.selectCapable) {
            try outJson.append(source.describe(format: .json, fields: fieldsList.detail))
         }
         return try Util.jsonToString(outJson, options: [.prettyPrinted])
      } else {
         // list IDs as string
         var ids: [String] = []
         for source in sources {
            ids.append(source.id)
         }
         return ids.joined(separator: "\n")
      }
   }

   /// Set sub-command
   public static func set(_ state: IMEState) throws -> String {
      // Switch to new ID
      guard let curr = try current() else {
         throw AppError.ime(.getCurrentFailed)
      }
      let currID = curr.id // Need to save here
      guard let _newID = state.newID else {
         throw AppError.ime(.missingTargetID)
      }

      _ = try select(id: _newID)
      // NOTE: The CJK IME internal mode has not been switched yet because the change happens asynchronously.

      if state.cjkRefresh { CJK.refresh(desiredID: _newID) }

      // Save to /tmp
      if state.save {
         let path = try getStoredPath(state.sessionID)
         let success = FS.write(path, currID)
         guard success else {
            throw AppError.ime(.saveFailed(path))
         }
      }
      return "" // DEBUG: Should return nothing ?
   }

   /// get sub-command
   public static func get(_ state: IMEState) throws -> String {
      guard let curr = try current() else {
         throw AppError.ime(.getCurrentFailed)
      }
      if state.detail {
         // curr IME detail as JSON
         let outJson: Any = try curr.describe(format: .json, fields: fieldsList.detail)
         return try Util.jsonToString(outJson, options: [.prettyPrinted])
      } else {
         // curr IME id as string
         return curr.id
      }
   }

   /// execute appropriate sub-command with refering state
   public static func execute(_ state: IMEState) throws -> String {
      switch state.subcmd {
      case "save":
         return try save(state)
      case "load":
         return try load(state)
      case "list":
         return try list(state)
      case "set":
         return try set(state)
      case "get":
         return try get(state)
      default:
         throw AppError.ime(.invalidSubCommand(state.subcmd ?? "Unknown"))
      }
   }
}
