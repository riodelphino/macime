public struct AppConfig {
    public var version: String = "3.0.2"
    public var tempDir: String = "/tmp/riodelphino.macime"
    public var sockPath: String = "/tmp/riodelphino.macimed.sock"
    public var macimePath: String = "/usr/local/bin/macime"
    public init() {}
}

public let config = AppConfig()
