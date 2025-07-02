import Cocoa
import InputMethodKit

enum OutputFormat {
    case json, raw
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

    static func listDetails(availableOnly: Bool) -> [[String: Any]] {
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

    func asDict() -> [String: Any] {
        return [
            "id": self.id,
            "localizedName": self.localizedName,
            "isSelectCapable": self.isSelectCapable,
            "isSelected": self.isSelected,
            "sourceLanguages": self.sourceLanguages
        ]
    }
}

// ╭────────────────────────────────────────────────────────────────────────────╮
// │                                   MAIN                                     │
// ╰────────────────────────────────────────────────────────────────────────────╯

let args = CommandLine.arguments.dropFirst()
var outputFormat: OutputFormat = .json
var showList = false
var showDetail = false
var availableOnly = false
var toggleTargets: [String]? = nil
var switchToID: String? = nil

// 引数パース
var i = 0
while i < args.count {
    let arg = args[i]
    switch arg {
    case "--output":
        i += 1
        if i < args.count {
            outputFormat = (args[i] == "raw") ? .raw : .json
        }
    case "--list":
        showList = true
    case "--detail":
        showDetail = true
    case "--available":
        availableOnly = true
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

// 出力関数
func printOutput(_ value: Any) {
    switch outputFormat {
    case .json:
        let jsonObject: Any
        if let string = value as? String {
            jsonObject = ["value": string]
        } else {
            jsonObject = value
        }
        if JSONSerialization.isValidJSONObject(jsonObject),
           let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
           let str = String(data: data, encoding: .utf8) {
            Swift.print(str)
        } else {
            Swift.print("{\"error\": \"Invalid JSON\"}")
        }
    case .raw:
        if let str = value as? String {
            Swift.print(str)
        } else if let arr = value as? [Any] {
            for item in arr {
                Swift.print(item)
            }
        } else if let dict = value as? [String: Any] {
            for (key, val) in dict {
                Swift.print("\(key): \(val)")
            }
        }
    }
}

// ❶ トグル
if let targets = toggleTargets {
    if let currentID = InputSource.current()?.id,
       let idx = targets.firstIndex(of: currentID) {
        let next = targets[(idx + 1) % targets.count]
        if let switched = InputSource.change(id: next) {
            printOutput((outputFormat == .json) ? switched.asDict() : switched.id)
        }
    } else if let first = targets.first, let switched = InputSource.change(id: first) {
        printOutput((outputFormat == .json) ? switched.asDict() : switched.id)
    } else {
        Swift.print("Toggle failed.")
    }
    exit(0)
}

// ❷ 切り替え
if let id = switchToID {
    if let switched = InputSource.change(id: id) {
        printOutput((outputFormat == .json) ? switched.asDict() : switched.id)
    } else {
        Swift.print("Switch failed.")
    }
    exit(0)
}

// ❸ 一覧系
if showDetail {
    let result = InputSource.listDetails(availableOnly: availableOnly)
    printOutput(result)
    exit(0)
}

if showList {
    let result = InputSource.listIDs(availableOnly: availableOnly)
    printOutput(result)
    exit(0)
}

// ❹ 現在のIME
if let current = InputSource.current() {
    printOutput((outputFormat == .json) ? current.id : current.id)
} else {
    Swift.print("No current input source")
}

