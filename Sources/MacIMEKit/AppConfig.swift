public struct AppConfig {
   public var version: String = "v3.0.0"
   public var tempDir: String = "/tmp/riodelphino.macime"
   public var sockPath: String = "/tmp/com.riodelphino.macimed.sock"
   public init() {}
}

public let config = AppConfig()
