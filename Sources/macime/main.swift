import Foundation
import InputMethodKit
import MacIMEKit

public let cmdSpec = CmdSpec(name: "macime", version: "3.0.0", help: Help.macime)
public let state = ArgParser.parse()
App.execute(state)

// ╭────────────────────────────────────────────────────────────╮
// │                          MAIN                              │
// ╰────────────────────────────────────────────────────────────╯

struct App {
    static func execute(_ state: CmdState) {
        do {
            try IMECore.ensureTempDirExists()

            switch state.subcmd {
            case "save":
                if let curr = try IMECore.current() {
                    let path = IMECore.getStoredPath(state.sessionID)
                    let success = File.write(path, curr.id)
                    guard success else {
                        throw AppError.saveFailed(path)
                    }
                }
            case "load":
                if let prev_id = IMECore.previous(session_id: state.sessionID) {
                    let _ = try IMECore.select(id: prev_id)
                }
            case "list":
                var sources: [TISInputSource]
                var outJson: [Any] = []
                var outStr: [String] = []
                sources = IMECore.list(selectCapable: state.selectCapable)
                if state.detail {
                    if state.json {
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
                    if state.json {
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
                if let prev = try IMECore.current() {
                    if let _newID = state.newID {
                        let _ = try IMECore.select(id: _newID)
                        // Save to /tmp
                        if state.save {
                            let path = IMECore.getStoredPath(state.sessionID)
                            let success = File.write(path, prev.id)
                            guard success else {
                                throw AppError.saveFailed(path)
                            }
                        }
                    }
                }
            case "get":
                if let curr = try IMECore.current() {
                    if state.detail {
                        if state.json {
                            // curr IME detail as JSON
                            try IO.outputJSON(curr.getInfo.json)
                        } else {
                            // curr IME detail as string
                            IO.out(curr.getInfo.str)
                        }
                    } else {
                        if state.json {
                            // curr IME id as JSON
                            try IO.outputJSON(curr.id)
                        } else {
                            // curr IME id as string
                            IO.out(curr.id)
                        }
                    }
                }
            default:
                IO.err("Invalid Sub-command: \(state.subcmd ?? "UNKNOWN")")
                exit(1)
            }
        } catch let e as AppError {
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
