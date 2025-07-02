import Cocoa
import InputMethodKit

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
            "id": id,
            "localizedName": localizedName,
            "isSelectCapable": isSelectCapable,
            "isSelected": isSelected,
            "sourceLanguages": sourceLanguages
        ]
    }
}

// ╭────────────────────────────────────────────────────────────╮
// │                         MAIN                              │
// ╰────────────────────────────────────────────────────────────╯

let args = CommandLine.arguments.dropFirst()
var showList = false
var showDetail = false
var showNameOnly = false
var availableOnly = false
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

// 1. toggle
if let targets = toggleTargets {
    if let currentID = InputSource.current()?.id,
       let idx = targets.firstIndex(of: currentID) {
        let next = targets[(idx + 1) % targets.count]
        if let switched = InputSource.change(id: next) {
            println(switched.id)
        }
    } else if let first = targets.first,
              let switched = InputSource.change(id: first) {
        println(switched.id)
    } else {
        println("Toggle failed.")
    }
    exit(0)
}

// 2. switch by ID
if let id = switchToID {
    if let switched = InputSource.change(id: id) {
        println(switched.id)
    } else {
        println("Switch failed.")
    }
    exit(0)
}

// 3. detail
if showDetail {
    let sources = InputSource.listDetails(availableOnly: availableOnly)
    for dict in sources {
        for (k, v) in dict {
            println("\(k): \(v)")
        }
        println("--------------------")
    }
    exit(0)
}

// 4. list
if showList {
    let list = showNameOnly
        ? InputSource.listNames(availableOnly: availableOnly)
        : InputSource.listIDs(availableOnly: availableOnly)
    for item in list {
        println(item)
    }
    exit(0)
}

// 5. current
if let current = InputSource.current() {
    println(showNameOnly ? current.localizedName : current.id)
} else {
    println("No current input source")
}
