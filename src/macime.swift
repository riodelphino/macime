import Cocoa
import Foundation
import InputMethodKit

// ╭───────────────────────────────────────────────────────────────╮
// │                             Const                             │
// ╰───────────────────────────────────────────────────────────────╯

let VERSION = "2.0.1"
let TEMP_DIR = "/tmp/riodelphino.macime/prev"

// ╭───────────────────────────────────────────────────────────────╮
// │                            struct                             │
// ╰───────────────────────────────────────────────────────────────╯

// Commmand line args
struct Opts {
    var selectCapable: Bool = false
    var subcmd: String? = nil
    var save: Bool = false
    var load: Bool = false
    var detail: Bool = false
    var json = false
    var newID: String? = nil
    var sessionID: String? = nil
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

    static func getStoredPath(_ sessionID: String?) -> String {
        var basename: String = ""
        if let sessionID = opts.sessionID {
            basename = sessionID
        } else {
            basename = "DEFAULT"
        }

        let path = TEMP_DIR + "/" + basename
        return path
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
    if i == 0 {
        switch arg {
        case "set":
            opts.subcmd = "set"
            if i + 1 < args.count {
                opts.newID = args[i + 1]
                i += 1
            } else {
                stderr("'set' sub-command requires IME ID")
                exit(1)
            }
            i += 1
            continue
        case "get", "list", "load":
            opts.subcmd = arg
            i += 1
            continue
        // case "save":
        //    opts.save = true
        default:
            stderr("'macime' requires sub-command: set|get|list|load")
            exit(1)
        }
    }

    switch arg {
    case "--detail":
        opts.detail = true
    case "--select-capable":
        opts.selectCapable = true
    case "--json":
        opts.json = true
    case "--save":
        opts.save = true
    // case "--load":
    //    opts.load = true
    case "--session-id":
        if i + 1 < args.count {
            opts.sessionID = args[i + 1]
            i += 1
        } else {
            stderr("'--session-id' requires variable")
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
if opts.subcmd == "list" {
    opts.newID = nil
}

switch opts.subcmd {
case "load":
    let path = MacIME.getStoredPath(opts.sessionID)
    let prev_id = try String(contentsOfFile: path, encoding: .utf8)
    if prev_id != "" {
        let curr = MacIME.change(id: prev_id)
        if curr != nil {
            // Success
        } else {
            stderr("Failed to load: \(prev_id)")
            exit(1)
        }
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
case "set":
    // Switch to new ID
    if let prev = MacIME.current() {
        if let _newID = opts.newID {
            let curr = MacIME.change(id: _newID)
            if curr != nil {
                if opts.save {  // Save to /tmp
                    let path = MacIME.getStoredPath(opts.sessionID)
                    try prev.id.write(toFile: path, atomically: true, encoding: .utf8)
                }
            } else {  // Switching error
                stderr("Failed to switch to: \(_newID)")
                exit(1)
            }
        }
    }
case "get":
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
                MacIME.outputJSON(curr.id)
            } else {
                // curr IME id as string
                stdout(curr.id)
            }
        }
    }
default:
    break
}
