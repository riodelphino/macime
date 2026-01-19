import Foundation

public struct Sock {
   public static func log(_ msg: String) {
      let timestamp = ISO8601DateFormatter().string(from: Date())
      let logMsg = "[\(timestamp)] \(msg)\n"
      if let data = logMsg.data(using: .utf8) {
         FileHandle.standardError.write(data)
      }
   }

   public static func cleanupSocket() -> Bool {
      return File.removePath(config.sockPath)
   }

   // ╭───────────────────────────────────────────────────────────────╮
   // │                    Command Processing                         │
   // ╰───────────────────────────────────────────────────────────────╯

   public static func processCommand(_ cmd: String) -> Response {  // TODO: This should be replaced with `import MacIMECore`
      let args = ArgParser.splitArgs(cmd)
      // let state: CmdState = ArgParser.parse(args)

      // NOT WORKS
      // let response: Response = IMECore.execute(state)
      // return response
      //
      // NOTE: -- UNFORTUNATELY, `TISInputSource` CANNOT GET/SET the IME OF FRONT APP FROM DAEMON SERVICE --
      // It always returns the default `com.apple.keylayout.ABC`.
      // See:
      //   - https://stackoverflow.com/questions/26612735/os-x-how-to-get-tisinputsourceref-keyboard-layout-of-current-active-window-of
      //   - https://leopard-adc.pepas.com/documentation/TextFonts/Reference/TextInputSourcesReference/TextInputSourcesReference.pdf?utm_source=chatgpt.com

      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/local/bin/macime")
      process.arguments = args

      let pipe = Pipe()
      process.standardOutput = pipe
      process.standardError = pipe

      do {
         try process.run()
         process.waitUntilExit()

         let data = pipe.fileHandleForReading.readDataToEndOfFile()
         if let output = String(data: data, encoding: .utf8) {
            return Response(status: .ok, content: output.isEmpty ? "OK\n" : output)
         }
         return Response(status: .err, content: "ERROR: No output\n")
      } catch {
         return Response(status: .err, content: "ERROR: \(error.localizedDescription)\n")
      }
   }

   // ╭───────────────────────────────────────────────────────────────╮
   // │                   Client Handler                              │
   // ╰───────────────────────────────────────────────────────────────╯

   public static func handleClient(_ client: Int32) {
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

      switch response.status {
      case .ok:
         log("Sending response: '\(response.content.trimmingCharacters(in: .newlines))'")
         let _ = write(client, response.content, response.content.count)
      case .err:
         log("Sending error   : '\(response.content.trimmingCharacters(in: .newlines))'")
         let _ = write(client, response.content, response.content.count)
      }
   }

   // ╭───────────────────────────────────────────────────────────────╮
   // │                    Daemon Main                                │
   // ╰───────────────────────────────────────────────────────────────╯

   public static func startDaemon() throws {
      let _ = cleanupSocket()

      let fd = socket(AF_UNIX, SOCK_STREAM, 0)
      guard fd >= 0 else {
         throw NSError(domain: "socket", code: -1, userInfo: ["msg": "socket() failed"])
      }

      log("Socket created: fd=\(fd)")

      defer { close(fd) }

      var addr = sockaddr_un()
      addr.sun_family = sa_family_t(AF_UNIX)

      let pathCStr = (config.sockPath as NSString).utf8String!
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

      log("Socket bound to \(config.sockPath)")

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

}
