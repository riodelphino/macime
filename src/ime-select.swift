import Cocoa
import InputMethodKit
import Foundation

// JSON出力用の構造体
struct InputSourceInfo: Codable {
    let id: String
    let localizedName: String
    let isSelectCapable: Bool
    let isSelected: Bool
    let sourceLanguages: [String]
}

class InputSource {
    fileprivate static var inputSources: [TISInputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        return inputSourceNSArray as! [TISInputSource]
    }

    fileprivate static var selectCapableInputSources: [TISInputSource] {
        return inputSources.filter { $0.isSelectCapable }
    }

    static func change(id: String) -> TISInputSource? {
        guard let inputSource = selectCapableInputSources.first(where: { $0.id == id }) else {
            return nil
        }
        TISSelectInputSource(inputSource)
        return inputSource
    }

    static func current() -> TISInputSource? {
        return selectCapableInputSources.first(where: { $0.isSelected })
    }

    static func listIDs(availableOnly: Bool) -> [String] {
        let sources = availableOnly ? selectCapableInputSources : inputSources
        return sources.map { $0.id }
    }

    static func listNames(availableOnly: Bool) -> [String] {
        let sources = availableOnly ? selectCapableInputSources : inputSources
        return sources.map { $0.localizedName }
    }

    static func listDetails(availableOnly: Bool) -> [InputSourceInfo] {
        let sources = availableOnly ? selectCapableInputSources : inputSources
        return sources.map { $0.asDict() }
    }
}

extension TISInputSource {
    func getProperty(_ key: CFString) -> AnyObject? {
        guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var localizedName: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var isSelectCapable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var isSelected: Bool {
        return getProperty(kTISPropertyInputSourceIsSelected) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as? [String] ?? []
    }

    func asDict() -> InputSourceInfo {
        return InputSourceInfo(
            id: id,
            localizedName: localizedName,
            isSelectCapable: isSelectCapable,
            isSelected: isSelected,
            sourceLanguages: sourceLanguages
        )
    }
}

// 保存・読み込み機能
class IMEStorage {
    private static let saveKey = "com.ime-select.saved-id"
    
    static func save(id: String) {
        UserDefaults.standard.set(id, forKey: saveKey)
        UserDefaults.standard.synchronize()
    }
    
    static func load() -> String? {
        return UserDefaults.standard.string(forKey: saveKey)
    }
}

// JSON出力用のヘルパー
func outputJSON<T: Encodable>(_ data: T) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    do {
        let jsonData = try encoder.encode(data)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
    } catch {
        print("JSON encoding error: \(error)")
    }
}

// ╭────────────────────────────────────────────────────────────╮
// │                         MAIN                              │
// ╰────────────────────────────────────────────────────────────╯

let args = Array(CommandLine.arguments.dropFirst())
var showList = false
var showDetail = false
var showNameOnly = false
var availableOnly = false
var useJSON = false
var saveCurrentID = false
var loadSavedID = false
var toggleTargets: [String]? = nil
var switchToID: String? = nil

// 引数パース
var i = 0
while i < args.count {
    let arg = args[i]
    switch arg {
    case "--list":
        showList = true
    case "--detail":
        showDetail = true
    case "--available":
        availableOnly = true
    case "--name":
        showNameOnly = true
    case "--json":
        useJSON = true
    case "--save":
        saveCurrentID = true
    case "--load":
        loadSavedID = true
    case "--toggle":
        i += 1
        if i < args.count {
            toggleTargets = args[i].split(separator: ",").map { String($0) }
        }
    case let id where id.starts(with: "com."):
        switchToID = id
    default:
        break
    }
    i += 1
}

// 実行関数
func println(_ str: String) {
    Swift.print(str)
}

// 1. save current ID
if saveCurrentID {
    if let current = InputSource.current() {
        IMEStorage.save(id: current.id)
        if useJSON {
            outputJSON(["action": "save", "id": current.id, "status": "success"])
        } else {
            println("Saved: \(current.id)")
        }
    } else {
        if useJSON {
            outputJSON(["action": "save", "status": "error", "message": "No current input source"])
        } else {
            println("Error: No current input source")
        }
    }
    exit(0)
}

// 2. load saved ID
if loadSavedID {
    if let savedID = IMEStorage.load() {
        if let switched = InputSource.change(id: savedID) {
            if useJSON {
                outputJSON(["action": "load", "id": switched.id, "status": "success"])
            } else {
                println(switched.id)
            }
        } else {
            if useJSON {
                outputJSON(["action": "load", "id": savedID, "status": "error", "message": "Failed to switch"])
            } else {
                println("Error: Failed to switch to \(savedID)")
            }
        }
    } else {
        if useJSON {
            outputJSON(["action": "load", "status": "error", "message": "No saved input source"])
        } else {
            println("Error: No saved input source")
        }
    }
    exit(0)
}

// 3. toggle
if let targets = toggleTargets {
    if let currentID = InputSource.current()?.id,
       let idx = targets.firstIndex(of: currentID) {
        let next = targets[(idx + 1) % targets.count]
        if let switched = InputSource.change(id: next) {
            if useJSON {
                outputJSON(["action": "toggle", "from": currentID, "to": switched.id, "status": "success"])
            } else {
                println(switched.id)
            }
        }
    } else if let first = targets.first,
              let switched = InputSource.change(id: first) {
        if useJSON {
            outputJSON(["action": "toggle", "to": switched.id, "status": "success"])
        } else {
            println(switched.id)
        }
    } else {
        if useJSON {
            outputJSON(["action": "toggle", "status": "error", "message": "Toggle failed"])
        } else {
            println("Toggle failed.")
        }
    }
    exit(0)
}

// 4. switch by ID
if let id = switchToID {
    if let switched = InputSource.change(id: id) {
        if useJSON {
            outputJSON(["action": "switch", "id": switched.id, "status": "success"])
        } else {
            println(switched.id)
        }
    } else {
        if useJSON {
            outputJSON(["action": "switch", "id": id, "status": "error", "message": "Switch failed"])
        } else {
            println("Switch failed.")
        }
    }
    exit(0)
}

// 5. detail
if showDetail {
    let sources = InputSource.listDetails(availableOnly: availableOnly)
    if useJSON {
        outputJSON(sources)
    } else {
        for info in sources {
            println("id: \(info.id)")
            println("localizedName: \(info.localizedName)")
            println("isSelectCapable: \(info.isSelectCapable)")
            println("isSelected: \(info.isSelected)")
            println("sourceLanguages: \(info.sourceLanguages)")
            println("--------------------")
        }
    }
    exit(0)
}

// 6. list
if showList {
    if showNameOnly {
        let names = InputSource.listNames(availableOnly: availableOnly)
        if useJSON {
            outputJSON(names)
        } else {
            for name in names {
                println(name)
            }
        }
    } else {
        let ids = InputSource.listIDs(availableOnly: availableOnly)
        if useJSON {
            outputJSON(ids)
        } else {
            for id in ids {
                println(id)
            }
        }
    }
    exit(0)
}

// 7. current (default)
if let current = InputSource.current() {
    if useJSON {
        if showNameOnly {
            outputJSON(["name": current.localizedName])
        } else {
            outputJSON(["id": current.id])
        }
    } else {
        println(showNameOnly ? current.localizedName : current.id)
    }
} else {
    if useJSON {
        outputJSON(["error": "No current input source"])
    } else {
        println("No current input source")
    }
}
