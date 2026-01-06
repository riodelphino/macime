import Cocoa
import Foundation
import InputMethodKit

// ╭───────────────────────────────────────────────────────────────╮
// │                             Const                             │
// ╰───────────────────────────────────────────────────────────────╯

let VERSION = "2.0.0"

// ╭───────────────────────────────────────────────────────────────╮
// │                            struct                             │
// ╰───────────────────────────────────────────────────────────────╯

// Commmand line args
struct Opts {
   var selectCapable: Bool = false
   var list: Bool = false
   var detail: Bool = false
   var json = false
   var shows: [String] = []
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
      return (_str, _json)
   }
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
   case "--select-capable":
      opts.selectCapable = true
   case "--json":
      opts.json = true
   case "--show":
      if i + 1 < args.count {
         let show = args[i + 1]
         switch show {
         case "prev":
            opts.shows.append("prev")
         case "curr":
            opts.shows.append("curr")
         case "both":
            opts.shows.append("prev")
            opts.shows.append("curr")
         default:
            stderr("'--show requires both|curr|prev'")
            exit(1)
         }
         i += 1
      } else {
         stderr("'--show' requires both|curr|prev")
         exit(1)
      }
   case "--version", "-v":
      stdout("macime " + VERSION)
      exit(0)
   default:
      opts.newID = arg  // IME method ID
      break
   }
   i += 1
}

// Prioritize `list` sub command
if opts.list == true {
   opts.newID = nil
}
// Return previous IME as default
if !opts.list {
   opts.shows = ["prev"]
}

if opts.list {
   var sources: [TISInputSource]
   var outJson: [Any] = []
   var outStr: [String] = []

   sources = MacIME.list(selectCapable: opts.selectCapable)

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
   var sources: [String: TISInputSource] = [:]
   // if sources["prev"] != nil {
   if let prev = MacIME.current() {
      sources["prev"] = prev
      var outJson: [String: Any] = [:]
      var outStr: [String] = []

      // Switch to new ID
      if let _newID = opts.newID {
         // Set & Get
         if let curr = MacIME.change(id: _newID) {
            sources["curr"] = curr
            if opts.detail {
               if opts.json {
                  // prev/curr IME detail as JSON
                  for show in opts.shows {
                     outJson[show] = sources[show]!.getInfo.json
                  }
                  MacIME.outputJSON(outJson)
               } else {
                  // prev/curr IME detail as string
                  for show in opts.shows {
                     outStr.append(sources[show]!.getInfo.str)
                  }
                  stdout(outStr.joined(separator: "\n"))
               }
            } else {
               if opts.json {
                  // prev/curr IME id as JSON
                  for show in opts.shows {
                     outJson[show] = sources[show]!.id
                  }
                  MacIME.outputJSON(outJson)
               } else {
                  // prev/curr IME id as string
                  for show in opts.shows {
                     outStr.append(sources[show]!.id)
                  }
                  stdout(outStr.joined(separator: "\n"))
               }
            }
         } else {  // Switching error
            stderr("Failed to switch to: \(_newID)")
            exit(1)
         }
      } else {
         // get current IME
         if let curr = MacIME.current() {
            if opts.detail {
               if opts.json {
                  // curr IME detail as JSON
                  MacIME.outputJSON(curr.getInfo.json)
               } else {
                  // curr IME detail as string
                  stdout(curr.getInfo.str)
               }
            } else {
               if opts.json {
                  // curr IME id as JSON
                  MacIME.outputJSON(curr.getInfo.json)  // TODO: NEED THIS ???
               } else {
                  // curr IME id as string
                  stdout(curr.id)
               }
            }
         } else {  // Switching error
            stderr("Failed to get current IME")
            exit(1)
         }

      }
   }
}
