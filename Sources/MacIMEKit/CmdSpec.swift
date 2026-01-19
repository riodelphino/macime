public struct CmdSpec {
   public let name: String  // macime|macimed
   public let version: String
   public let help: String
   public init(name: String, version: String, help: String) {
      self.name = name
      self.version = version
      self.help = help
   }
}
