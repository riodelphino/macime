// Keeps commmand line args
public struct CmdState {
   public var subcmd: String? = nil
   public var save: Bool = false
   public var newID: String? = nil
   public var selectCapable: Bool = false
   public var detail: Bool = false
   public var json = false
   public var sessionID: String? = nil
   public init() {}
}
