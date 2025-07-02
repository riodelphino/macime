import Cocoa
import InputMethodKit

class InputSource {
    fileprivate static var inputSources: [TISInputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        return inputSourceNSArray as! [TISInputSource]
    }

    fileprivate static var selectCapableInputSources: [TISInputSource] {
        return inputSources.filter({ $0.isSelectCapable })
    }

    static func change(id: String) {
        guard let inputSource = selectCapableInputSources.first(where: { $0.id == id }) else {
            Swift.print("Input source not found or not selectable.")
            return
        }
        TISSelectInputSource(inputSource)
    }

    static func printCurrent() {
        for source in selectCapableInputSources {
            if source.isSelected {
                Swift.print(source.id)
                return
            }
        }
        Swift.print("No selected input source found.")
    }

    static func printList() {
        for source in selectCapableInputSources {
            Swift.print(source.id)
        }
    }

    static func printDetails() {
        for source in inputSources {
            Swift.print("id:[\(source.id)]")
            Swift.print("localizedName:[\(source.localizedName)]")
            Swift.print("isSelectCapable:[\(source.isSelectCapable)]")
            Swift.print("isSelected:[\(source.isSelected)]")
            Swift.print("sourceLanguages:[\(source.sourceLanguages)]")
            Swift.print("--------------------")
        }
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
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }
}

//  ╭──────────────────────────────────────────────────────────────────────────────╮
//  │                                  Main Logic                                  │
//  ╰──────────────────────────────────────────────────────────────────────────────╯

let args = CommandLine.arguments

switch args.count {
case 1:
    // No argument: show current IME
    InputSource.printCurrent()

case 2:
    switch args[1] {
    case "--list":
        InputSource.printList()
    case "--list-detail":
        InputSource.printDetails()
    default:
        InputSource.change(id: args[1])
    }

default:
    Swift.print("Usage:")
    Swift.print("  ime-select                 # Show current IME ID")
    Swift.print("  ime-select --list          # List all selectable IME IDs")
    Swift.print("  ime-select --list-detail   # List all IMEs with detail")
    Swift.print("  ime-select <id>            # Switch to specific IME")
}

