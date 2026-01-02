import Cocoa
import Foundation
import InputMethodKit

// JSON output structure
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
    inputSources.filter(\.isSelectCapable)
  }

  static func change(id: String) -> TISInputSource? {
    guard let inputSource = selectCapableInputSources.first(where: { $0.id == id }) else {
      return nil
    }
    TISSelectInputSource(inputSource)
    return inputSource
  }

  static func current() -> TISInputSource? {
    guard let currentInputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    else {
      return nil
    }
    return currentInputSource
  }

  static func listIDs(availableOnly: Bool) -> [String] {
    let sources = availableOnly ? selectCapableInputSources : inputSources
    return sources.map(\.id)
  }

  static func listNames(availableOnly: Bool) -> [String] {
    let sources = availableOnly ? selectCapableInputSources : inputSources
    return sources.map(\.localizedName)
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

  func asDict() -> InputSourceInfo {
    InputSourceInfo(
      id: id,
      localizedName: localizedName,
      isSelectCapable: isSelectCapable,
      isSelected: isSelected,
      sourceLanguages: sourceLanguages as NSArray as! [String],
    )
  }
}

//
class IMEStorage {
  private static let saveKey = "com.macime.saved-id"

  static func save(id: String) {
    UserDefaults.standard.set(id, forKey: saveKey)
    UserDefaults.standard.synchronize()
  }

  static func load() -> String? {
    UserDefaults.standard.string(forKey: saveKey)
  }
}

// JSON output helper for Codable
func outputCodableJSON(_ data: some Encodable) {
  do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let jsonData = try encoder.encode(data)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
      print(jsonString)
    }
  } catch {
    eprintln("JSON encoding error: \(error)")
    exit(1)
  }
}

// JSON output helper for Dictionary and Array (Any) ※ only for swift type
func outputJSON(_ data: Any) {
  do {
    let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
    if let jsonString = String(data: jsonData, encoding: .utf8) {
      print(jsonString)
    }
  } catch {
    eprintln("JSON serialization error: \(error)")
    exit(1)
  }
}

// ╭────────────────────────────────────────────────────────────╮
// │                          MAIN                              │
// ╰────────────────────────────────────────────────────────────╯

let args = Array(CommandLine.arguments.dropFirst())
var showList = false
var showDetail = false
var showNameOnly = false
var availableOnly = false
var useJSON = false
var saveCurrentID = false
var loadSavedID = false
var toggleTargets: [String]?
var switchToID: String?

// Parse args
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
  if switchToID != nil, loadSavedID == true {
    error("--save option and switchToID cannot be specified simultaneously.")
  }
  if let targets = toggleTargets, !targets.isEmpty, loadSavedID == true {
    error("--load and --toggle cannot be specified simultaneously.")
  }
  i += 1
}

func error(_ message: String) {
  let msg = "ERROR: " + message
  if useJSON {
    outputJSON(["error": msg])
  } else {
    eprintln(msg)
  }
  exit(1)
}

func eprintln(_ message: String) {
  if let data = (message + "\n").data(using: .utf8) {
    FileHandle.standardError.write(data)
  }
}

// Excuting function
func println(_ str: String) {
  Swift.print(str)
}

// 1. save current ID (and optionally switch)
if saveCurrentID {
  if let current = InputSource.current() {
    IMEStorage.save(id: current.id)

    // If an ID is specified, switch to that ID after saving
    if let targetID = switchToID {
      if let switched = InputSource.change(id: targetID) {
        if useJSON {
          outputJSON([
            "action": "save_and_switch", "saved": current.id,
            "switched_to": switched.id,
            "status": "success",
          ])
        } else {
          println("Saved: \(current.id), Switched to: \(switched.id)")
        }
      } else {
        if useJSON {
          outputJSON([
            "action": "save_and_switch", "saved": current.id, "target": targetID,
            "status": "switch_failed",
          ])
        } else {
          println("Saved: \(current.id), but failed to switch to: \(targetID)")
        }
      }
    } else {
      if useJSON {
        outputJSON(["action": "save", "id": current.id, "status": "success"])
      } else {
        println("Saved: \(current.id)")
      }
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
        outputJSON([
          "action": "load", "id": savedID, "status": "error",
          "message": "Failed to switch",
        ])
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
  // For debugging: Check available input sources
  let availableIDs = InputSource.listIDs(availableOnly: true)
  let validTargets = targets.filter { availableIDs.contains($0) }

  if validTargets.isEmpty {
    if useJSON {
      outputJSON(
        [
          "action": "toggle", "status": "error", "message": "No valid targets found",
          "targets": targets, "available": availableIDs,
        ] as [String: Any])
    } else {
      println("Error: No valid targets found")
      println("Targets: \(targets)")
      println("Available: \(availableIDs)")
    }
    exit(0)
  }

  if let currentID = InputSource.current()?.id,
    let idx = validTargets.firstIndex(of: currentID)
  {
    let next = validTargets[(idx + 1) % validTargets.count]
    if let switched = InputSource.change(id: next) {
      if useJSON {
        outputJSON([
          "action": "toggle", "from": currentID, "to": switched.id, "status": "success",
        ])
      } else {
        println(switched.id)
      }
    }
  } else if let first = validTargets.first,
    let switched = InputSource.change(id: first)
  {
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

// 4. switch by ID (without `--save`)
if let id = switchToID, !saveCurrentID {
  if let switched = InputSource.change(id: id) {
    if useJSON {
      outputJSON(["action": "switch", "id": switched.id, "status": "success"])
    } else {
      println(switched.id)
    }
  } else {
    if useJSON {
      outputJSON([
        "action": "switch", "id": id, "status": "error", "message": "Switch failed",
      ])
    } else {
      println("Switch failed.")
    }
  }
  exit(0)
}

// 5. detail
if showDetail, !showList {
  if let current = InputSource.current() {
    if useJSON {
      outputCodableJSON(current.asDict())
    } else {
      println("id: \(current.id)")
      println("localizedName: \(current.localizedName)")
      println("isSelectCapable: \(current.isSelectCapable)")
      println("isSelected: \(current.isSelected)")
      println("sourceLanguages: \(current.sourceLanguages)")
      println("--------------------")
    }
  } else {
    if useJSON {
      outputJSON(["error": "No current input source"])
    } else {
      println("No current input source")
    }
  }
  exit(0)
}

// 6. list
if showList {
  if showDetail {
    let details = InputSource.listDetails(availableOnly: availableOnly)
    if useJSON {
      outputCodableJSON(details)
    } else {
      for detail in details {
        println("id: \(detail.id)")
        println("localizedName: \(detail.localizedName)")
        println("isSelectCapable: \(detail.isSelectCapable)")
        println("isSelected: \(detail.isSelected)")
        println("sourceLanguages: \(detail.sourceLanguages)")
        println("--------------------")
      }
    }
  } else if showNameOnly {
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
