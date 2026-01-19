import Foundation

let SOCKET_PATH = "/tmp/riodelphino.macimed.sock"

// ╭───────────────────────────────────────────────────────────────╮
// │                        Utilities                              │
// ╰───────────────────────────────────────────────────────────────╯

func log(_ msg: String) {
   let timestamp = ISO8601DateFormatter().string(from: Date())
   let logMsg = "[\(timestamp)] \(msg)\n"
   if let data = logMsg.data(using: .utf8) {
      FileHandle.standardError.write(data)
   }
}

func cleanupSocket() {
   try? FileManager.default.removeItem(atPath: SOCKET_PATH)
}

// ╭───────────────────────────────────────────────────────────────╮
// │                    Command Processing                         │
// ╰───────────────────────────────────────────────────────────────╯

func processCommand(_ cmd: String) -> String {  // TODO: This should be replaced with `import MacIMECore`
   let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
   let parts = trimmed.split(separator: " ", maxSplits: 3).map(String.init)

   guard parts.count > 0 else {
      return "ERROR: Empty command\n"
   }

   // Execute macime command as subprocess TODO: This should be replaced with `import MacIMECore`
   let process = Process()
   process.executableURL = URL(fileURLWithPath: "/usr/local/bin/macime")
   process.arguments = parts

   let pipe = Pipe()
   process.standardOutput = pipe
   process.standardError = pipe

   do {
      try process.run()
      process.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let output = String(data: data, encoding: .utf8) {
         return output.isEmpty ? "OK\n" : output
      }
      return "ERROR: No output\n"
   } catch {
      return "ERROR: \(error.localizedDescription)\n"
   }
}

// ╭───────────────────────────────────────────────────────────────╮
// │                   Client Handler                              │
// ╰───────────────────────────────────────────────────────────────╯

func handleClient(_ client: Int32) {
   defer { close(client) }

   log("Client connected: fd=\(client)")

   var buffer = [UInt8](repeating: 0, count: 4096)
   let bytesRead = read(client, &buffer, buffer.count)

   guard bytesRead > 0 else {
      log("Client read failed or EOF")
      return
   }

   let command =
      String(bytes: buffer[0..<bytesRead], encoding: .utf8)?.trimmingCharacters(
         in: .whitespacesAndNewlines) ?? ""

   log("Received command: '\(command)'")

   let response = processCommand(command)

   log("Sending response: '\(response.trimmingCharacters(in: .newlines))'")

   let _ = write(client, response, response.count)
}

func getSocketPath() -> String {
   // let socketPath = ProcessInfo.processInfo.environment["MACIME_SOCKET_PATH"] ?? SOCKET_PATH
   return SOCKET_PATH
}

// ╭───────────────────────────────────────────────────────────────╮
// │                    Daemon Main                                │
// ╰───────────────────────────────────────────────────────────────╯

func startDaemon() throws {
   cleanupSocket()

   let fd = socket(AF_UNIX, SOCK_STREAM, 0)
   guard fd >= 0 else {
      throw NSError(domain: "socket", code: -1, userInfo: ["msg": "socket() failed"])
   }

   log("Socket created: fd=\(fd)")

   defer { close(fd) }

   var addr = sockaddr_un()
   addr.sun_family = sa_family_t(AF_UNIX)

   let pathCStr = (SOCKET_PATH as NSString).utf8String!
   strncpy(
      &addr.sun_path.0, pathCStr,
      MemoryLayout.size(ofValue: addr.sun_path) - 1)

   let bindResult = withUnsafePointer(to: &addr) { ptr in
      ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
         bind(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
   }

   guard bindResult == 0 else {
      throw NSError(domain: "bind", code: -1, userInfo: ["msg": "bind() failed"])
   }

   log("Socket bound to \(SOCKET_PATH)")

   guard listen(fd, 5) == 0 else {
      throw NSError(domain: "listen", code: -1, userInfo: ["msg": "listen() failed"])
   }

   log("Listening for connections...")

   while true {
      let client = accept(fd, nil, nil)
      guard client >= 0 else {
         log("accept() failed")
         continue
      }

      DispatchQueue.global().async {
         handleClient(client)
      }
   }
}

// ╭───────────────────────────────────────────────────────────────╮
// │                        Entry Point                            │
// ╰───────────────────────────────────────────────────────────────╯

do {
   log("macimed v1.0 starting...")
   try startDaemon()
} catch {
   log("ERROR: \(error)")
   exit(1)
}
