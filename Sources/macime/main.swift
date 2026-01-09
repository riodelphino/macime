import Foundation
import InputMethodKit

// ╭───────────────────────────────────────────────────────────────╮
// │                             Const                             │
// ╰───────────────────────────────────────────────────────────────╯

let VERSION = "2.2.3"
let DEFAULT_TEMP_DIR = "/tmp/riodelphino.macime"
let HELP_STR = """
   Usage: macime [-v | --version] [-h | --help] [get|set|load}list] [<args>]

   Get current IME
      macime get [--detail] [--json]

   Set IME 
      macime set <IME_id> [--save] [--session-id <session_id>]

      Set IME only (no save)
         macime set <IME_id>
      
      Set IME while saving current IME to `DEFAULT` file in temp dir
         macime set <IME_id> --save
      
      Set IME while saving current IME to `<session_id>` file in temp dir
         macime set <IME_id> --save --session-id <session_id>

   Load (restore) IME
      macime load [--session-id <session_id>]

      Load previouse IME from `DEFAULT` file in temp dir
         macime load

      Load previous IME from `<session_id>` file in temp dir
         macime load --session-id <session_id>

   List IME
      macime list [--detail] [--select-capable] [--json]


   OPTIONS:

      --detail
         Show detailed IME info
         
      --select-capable
         Show only selectable IME

      --json
         Output as json

      --save
         Save current IME

      --session-id <session_id>
         Specify the save filename

   """

// ╭───────────────────────────────────────────────────────────────╮
// │                            struct                             │
// ╰───────────────────────────────────────────────────────────────╯

// Commmand line args
struct Opts {
   var subcmd: String? = nil
   var save: Bool = false
   var newID: String? = nil
   var selectCapable: Bool = false
   var detail: Bool = false
   var json = false
   var sessionID: String? = nil
}

// ╭───────────────────────────────────────────────────────────────╮
// │                             enum                              │
// ╰───────────────────────────────────────────────────────────────╯

enum MacIMEError: Error {
   case notFound(String)
   case selectFailed(String, OSStatus)
   case getCurrentFailed
   case getPreviousFailed(String?)
   case createTempDirFailed(String)
   case saveFailed(String)
   case loadFailed(String)
   case jsonSerializationFailed(String)
}

// Input/Output
enum IO {
   // stdout
   static func out(_ msg: String) {
      Swift.print(msg)
   }
   // stderr
   static func err(_ msg: String) {
      if let data = (msg + "\n").data(using: .utf8) {
         FileHandle.standardError.write(data)
      }
   }

   // outputJSON
   static func outputJSON(_ value: Any) throws {
      do {
         let data = try JSONSerialization.data(withJSONObject: value)
         FileHandle.standardOutput.write(data)
         FileHandle.standardOutput.write("\n".data(using: .utf8)!)
      } catch {
         throw MacIMEError.jsonSerializationFailed("Invalid JSON Object")
      }
   }
}

// File system
enum FS {
   static func createDir(_ dirPath: String) -> Bool {
      do {
         try FileManager.default.createDirectory(
            atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
      } catch {
         return false
      }
      return true
   }

   static func pathExists(_ path: String) -> Bool {
      return FileManager.default.fileExists(atPath: path)
   }

   static func read(_ path: String) -> String? {
      do {
         let content = try String(contentsOfFile: path, encoding: .utf8)
         return content
      } catch {
         return nil
      }
   }

   static func write(_ path: String, _ content: String) -> Bool {
      do {
         try content.write(toFile: path, atomically: true, encoding: .utf8)
         return true
      } catch {
         return false
      }
   }
}

// Utilities
enum Util {
   static func jsonToString(_ data: Any) throws -> String {
      let jsonData = try JSONSerialization.data(
         withJSONObject: data,
         options: .prettyPrinted
      )
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
         throw MacIMEError.loadFailed("Invalid UTF-8 JSON")
      }
      return jsonString
   }
}

// Arguments
enum ARG {
   static func parse() -> Opts {
      let args = Array(CommandLine.arguments.dropFirst())
      var opts = Opts()

      // Parse args
      var i = 0
      while i < args.count {
         let arg = args[i]
         if i == 0 {
            switch arg {
            case "set":
               opts.subcmd = "set"
               if i + 1 < args.count {
                  opts.newID = args[i + 1]
                  i += 1
               } else {
                  IO.err("Usage: 'macime set <IME_ID> [options]'")
                  exit(1)
               }
               i += 1
               continue
            case "get", "list", "load":
               opts.subcmd = arg
               i += 1
               continue
            case "--version", "-v":
               IO.out("macime " + VERSION)
               exit(0)
            case "--help", "-h":
               IO.out(HELP_STR)
               exit(0)
            default:
               IO.err("Usage: 'macime set|get|list|load [options]'")
               exit(1)
            }
         }

         if arg.hasPrefix("--") {
            switch arg {
            case "--detail":
               opts.detail = true
            case "--select-capable":
               opts.selectCapable = true
            case "--json":
               opts.json = true
            case "--save":
               opts.save = true
            case "--session-id":
               if i + 1 < args.count {
                  opts.sessionID = args[i + 1]
                  i += 1
               } else {
                  IO.err("Usage: 'macime set|load --session-id <session_id>'")
                  exit(1)
               }
            default:
               IO.err("Invalid option: \(arg)")
               exit(1)
            }
         } else {
            opts.newID = arg  // IME method ID
         }
         i += 1
      }

      // Prioritize `list` sub command
      if opts.subcmd == "list" {
         opts.newID = nil
      }

      // dump(opts, name: "opts")  // for debug

      return opts
   }
}

// ╭───────────────────────────────────────────────────────────────╮
// │                            Classes                            │
// ╰───────────────────────────────────────────────────────────────╯

class MacIME {
   static var sources: [TISInputSource] {
      let sourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
      return sourceNSArray as! [TISInputSource]
   }

   static func select(id: String) throws -> TISInputSource {
      guard let source = sources.first(where: { $0.id == id }) else {
         throw MacIMEError.notFound(id)
      }
      let ret = TISSelectInputSource(source)

      if ret != 0 {
         throw MacIMEError.selectFailed(id, ret)
      }
      return source
   }

   static func current() throws -> TISInputSource? {
      guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
         throw MacIMEError.getCurrentFailed
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

   static func previous(session_id: String?) -> String? {
      let path = getStoredPath(session_id)
      let prev_id = FS.read(path)
      return prev_id
   }

   static func getTempDir() -> String {
      let tempDir = ProcessInfo.processInfo.environment["MACIME_TEMP_DIR"] ?? DEFAULT_TEMP_DIR
      return tempDir
   }

   static func getStoredPath(_ sessionID: String?) -> String {
      let basename = sessionID ?? "DEFAULT"
      return getTempDir() + "/" + basename
   }

   static func ensureTempDirExists() throws {
      let tempDir = getTempDir()
      if !FS.pathExists(tempDir) {
         guard FS.createDir(tempDir) else {
            throw MacIMEError.createTempDirFailed(tempDir)
         }
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

struct App {
   static func run(_ opts: Opts) {
      do {
         try MacIME.ensureTempDirExists()

         switch opts.subcmd {
         case "load":
            if let prev_id = MacIME.previous(session_id: opts.sessionID) {
               let _ = try MacIME.select(id: prev_id)
            }
         case "list":
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
                  try IO.outputJSON(outJson)
               } else {
                  // list detail as str
                  for source in sources {
                     outStr.append(source.getInfo.str)
                  }
                  IO.out(outStr.joined(separator: "\n"))
               }
            } else {
               if opts.json {
                  // list id as json
                  for source in sources {
                     outJson.append(source.id)
                  }
                  try IO.outputJSON(outJson)
               } else {
                  // list id as str
                  for source in sources {
                     outStr.append(source.id)
                  }
                  IO.out(outStr.joined(separator: "\n"))
               }
            }
         case "set":
            // Switch to new ID
            if let prev = try MacIME.current() {
               if let _newID = opts.newID {
                  let _ = try MacIME.select(id: _newID)
                  // Save to /tmp
                  if opts.save {
                     let path = MacIME.getStoredPath(opts.sessionID)
                     let success = FS.write(path, prev.id)
                     guard success else {
                        throw MacIMEError.saveFailed(path)
                     }
                  }
               }
            }
         case "get":
            if let curr = try MacIME.current() {
               if opts.detail {
                  if opts.json {
                     // curr IME detail as JSON
                     try IO.outputJSON(curr.getInfo.json)
                  } else {
                     // curr IME detail as string
                     IO.out(curr.getInfo.str)
                  }
               } else {
                  if opts.json {
                     // curr IME id as JSON
                     try IO.outputJSON(curr.id)
                  } else {
                     // curr IME id as string
                     IO.out(curr.id)
                  }
               }
            }
         default:
            IO.err("Usage: 'macime set|get|list|load [options]'")
            exit(1)
         }
      } catch let e as MacIMEError {
         switch e {
         case .notFound(let id):
            IO.err("IME not found: '\(id)'")
         case .selectFailed(let id, let osstatus):
            IO.err("IME switch failed: '\(id)' (\(String(osstatus)))")
         case .getCurrentFailed:
            IO.err("Cannot get current IME")
         case .createTempDirFailed(let dir):
            IO.err("Cannot create temp directory: '\(dir)'")
         case .jsonSerializationFailed(let msg):
            IO.err("Serializing JSON failed: \(msg)")
         default:
            IO.err("Unhandled error: \(e)")
         }
         exit(1)
      } catch {
         IO.err("Unexpected error: \(error)")
         exit(1)
      }

   }
}

let opts = ARG.parse()
App.run(opts)
