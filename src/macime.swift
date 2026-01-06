import Cocoa
import Foundation
import InputMethodKit

// ╭───────────────────────────────────────────────────────────────╮
// │                            struct                             │
// ╰───────────────────────────────────────────────────────────────╯

// Commmand line args
struct Opts {
   var selectCapable: Bool = false
   var list: Bool = false
   var detail: Bool = false
   var json = false
   var show: String? = nil  // ["curr","prev"] に出来るんじゃ？ loop にできるし
   var newID: String? = nil
}

// ╭───────────────────────────────────────────────────────────────╮
// │                       Global functions                        │
// ╰───────────────────────────────────────────────────────────────╯

// stderr
func stderr(_ msg: String) {
   if let data = (msg + "\n").data(using: .utf8) {
      FileHandle.standardError.write(data)
   }
}

// stdout
func stdout(_ msg: String) {
   Swift.print(msg)
}

// Convet json to human-readable string (Only for test)
func jsonToString(_ data: Any) -> String? {
   do {
      let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
         return jsonString
      }
      return nil
   } catch {
      stderr("JSON serialization error: \(error)")
      exit(1)
   }
}

// ╭───────────────────────────────────────────────────────────────╮
// │                            Classes                            │
// ╰───────────────────────────────────────────────────────────────╯

class MacIME {
   fileprivate static var sources: [TISInputSource] {
      let sourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
      return sourceNSArray as! [TISInputSource]
   }

   static func change(id: String) -> TISInputSource? {
      guard let source = sources.first(where: { $0.id == id }) else {
         return nil
      }
      TISSelectInputSource(source)
      return source
   }

   static func current() -> TISInputSource? {
      guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
      else {
         return nil
      }
      return source
   }

   static func list(selectCapable: Bool) -> [TISInputSource] {
      if selectCapable {
         return sources.filter(\.isSelectCapable)
      } else {
         return sources
      }
   }

   // static func outputJSON<T: Encodable>(_ value: T) {
   static func outputJSON(_ value: Any) {
      do {
         let data = try JSONSerialization.data(withJSONObject: value)
         FileHandle.standardOutput.write(data)
         FileHandle.standardOutput.write("\n".data(using: .utf8)!)
      } catch {
         stderr("JSON serialization error: \(error)")
         exit(1)
      }
   }

}

// Extend TISInputSource for easy access to the properties
extension TISInputSource {
   func getProperty(_ key: CFString) -> AnyObject? {
      guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
      return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
   }
   var id: String {
      getProperty(kTISPropertyInputSourceID) as! String
   }
   var localizedName: String {
      getProperty(kTISPropertyLocalizedName) as! String
   }
   var isSelectCapable: Bool {
      getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
   }
   var isSelected: Bool {
      getProperty(kTISPropertyInputSourceIsSelected) as! Bool
   }
   var sourceLanguages: [String] {
      getProperty(kTISPropertyInputSourceLanguages) as? [String] ?? []
   }

   // Return IME info as specific data type
   // func getInfo() -> (str: String, json: [String: Any]) { // TODO: REMOVE
   var getInfo: (str: String, json: [String: Any]) {
      var _str = ""
      var _json: [String: Any] = [:]
      _json = [
         "id": id,
         "localizedName": localizedName,
         "isSelectCapable": isSelectCapable,
         "isSelected": isSelected,
         "sourceLanguages": sourceLanguages,
      ]
      _str =
         "id: \(id)\n"
         + "localizedName: \(localizedName)\n"
         + "isSelectCapable: \(isSelectCapable)\n"
         + "isSelected: \(isSelected)\n"
         + "sourceLanguages: \(sourceLanguages)\n"
         + "\n"
      return (_str, _json)
   }

   // // Return IME info as proper data type // TODO: REMOVE
   // func getInfo(opts: Opts) -> (id: String, str: String, json: [String: Any]) {
   //    if opts.detail {
   //       if opts.json {
   //          return getInfoAs()
   //       } else {
   //          return getInfoAs()
   //       }
   //    } else {
   //       if opts.json {
   //          return getInfoAs()
   //       } else {
   //          return getInfoAs()
   //       }
   //    }
   // }
}

// ╭────────────────────────────────────────────────────────────╮
// │                          MAIN                              │
// ╰────────────────────────────────────────────────────────────╯

let args = Array(CommandLine.arguments.dropFirst())
var opts = Opts()

// Parse args
var i = 0
while i < args.count {
   let arg = args[i]
   if i == 0, arg == "list" {
      opts.list = true
   }
   switch arg {
   case "--detail":
      opts.detail = true
   case "--available":
      opts.selectCapable = true
   case "--json":
      opts.json = true
   case "--show":
      if i + 1 < args.count {
         opts.show = args[i + 1]
         i += 1
      } else {
         stderr("'--show' requires both|curr|prev")
      }
   default:
      opts.newID = arg  // IME method ID
      break
   }
   i += 1
}
if !opts.list {
   if opts.show == nil {
      opts.show = "curr"  // As default
   }
   if opts.newID == nil {
      opts.show = "curr"  // ⭐️ list ではなく、newID が指定なし: get したいだけの "macime" のみだった場合の処理。あとのGet のとこに影響あり
   }
}

// Prioritize `list` sub command
if opts.list == true {
   opts.newID = nil
}

// var outJson: Dictionary<String, Any> = [:]

var sources: [TISInputSource]

sources = MacIME.list(selectCapable: opts.selectCapable)
if opts.list {
   var outJson: [Any] = []
   var outStr: [String] = []

   if opts.detail {
      if opts.json {
         // list detail as json
         for source in sources {
            outJson.append(source.getInfo.json)
         }
         MacIME.outputJSON(outJson)
      } else {
         // list detail as str
         for source in sources {
            outStr.append(source.getInfo.str)
         }
         stdout(outStr.joined(separator: "\n"))
      }
   } else {
      if opts.json {
         // list id as json
         for source in sources {
            outJson.append(source.id)
         }
         MacIME.outputJSON(outJson)
      } else {
         // list id as str
         for source in sources {
            outStr.append(source.id)
         }
         stdout(outStr.joined(separator: "\n"))
      }
   }
} else {  // Set or Get
   if let prev = MacIME.current() {
      var outJson: [String: Any] = [:]
      var outStr: [String] = []

      // Switch to new ID
      if let _newID = opts.newID {
         // Set & Get
         if let curr = MacIME.change(id: _newID) {
            if opts.detail {
               if opts.json {
                  // prev/curr IME detail as JSON
                  if opts.show == "both" || opts.show == "prev" {
                     outJson["prev"] = prev.getInfo.json
                  }
                  if opts.show == "both" || opts.show == "curr" {
                     outJson["curr"] = curr.getInfo.json
                  }
                  MacIME.outputJSON(outJson)
               } else {
                  // prev/curr IME detail as string
                  if opts.show == "both" || opts.show == "prev" {
                     outStr.append(prev.getInfo.str)
                  }
                  if opts.show == "both" || opts.show == "curr" {
                     outStr.append(curr.getInfo.str)
                  }
                  stdout(outStr.joined(separator: "\n"))
               }
            } else {
               if opts.json {
                  // prev/curr IME id as JSON
                  if opts.show == "both" || opts.show == "prev" {
                     outJson["prev"] = prev.id
                  }
                  if opts.show == "both" || opts.show == "curr" {
                     outJson["curr"] = curr.id
                  }
               } else {
                  // prev/curr IME id as string
                  if opts.show == "both" || opts.show == "prev" {
                     outStr.append(prev.id)
                  }
                  if opts.show == "both" || opts.show == "curr" {
                     outStr.append(curr.id)
                  }
                  stdout(outStr.joined(separator: "\n"))
               }
            }
         } else {  // Switching error
            stderr("failed to switch to: \(_newID)")
            exit(1)
         }
      } else {
         // TODO: get current ID

      }
   }
}
