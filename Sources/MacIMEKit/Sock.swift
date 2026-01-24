import Foundation

public struct Sock {
   public static func log(_ msg: String) {
      let formatter = ISO8601DateFormatter()
      formatter.timeZone = .current
      let timestamp = formatter.string(from: Date())

      let logMsg = "[\(timestamp)] \(msg)\n"
      if let data = logMsg.data(using: .utf8) {
         FileHandle.standardError.write(data)  // standardOutput is not appropriate here
      }
   }

   public static func cleanupSocket() -> Bool {
      return File.removePath(Config.sockPath)
   }

   // ╭───────────────────────────────────────────────────────────────╮
   // │                    Command Processing                         │
   // ╰───────────────────────────────────────────────────────────────╯

   public static func processCommand(_ cmd: String) throws -> String {

      // NOT WORKS
      // let args = ArgParser.splitArgs(cmd)
      // let state: CmdState = ArgParser.parse(args)
      // let response: Response = IMECore.execute(state)
      // return response
      //
      // NOTE: -- UNFORTUNATELY, `TISInputSource` CANNOT GET/SET the IME OF FRONT APP FROM DAEMON SERVICE --
      // It always returns the default `com.apple.keylayout.ABC`.
      // See:
      //   - https://stackoverflow.com/questions/26612735/os-x-how-to-get-tisinputsourceref-keyboard-layout-of-current-active-window-of
      //   - https://leopard-adc.pepas.com/documentation/TextFonts/Reference/TextInputSourcesReference/TextInputSourcesReference.pdf?utm_source=chatgpt.com

      let args = CmdArgs.splitArgs(cmd)

      let process = Process()
      process.executableURL = URL(fileURLWithPath: Config.macimePath)
      process.arguments = args

      let pipe = Pipe()
      process.standardOutput = pipe
      process.standardError = pipe

      try process.run()
      process.waitUntilExit()

      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      guard let output = String(data: data, encoding: .utf8) else {
         throw SockError.dataNotRecieved
      }
      return output
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

      log("Received command: \(command)")

      var ret: String = ""

      do {
         let ms = try Util.elapsed {
            ret = try processCommand(command)
         }
         log("Elapsed time    : \(ms)ms")

         var msg = ret.trimmingCharacters(in: .newlines)
         msg = msg.isEmpty ? "OK" : msg
         log("Sending response: \(msg)")
         let _ = write(client, ret, ret.count)
         shutdown(client, SHUT_WR)
         return
      } catch let e as AppError {
         log("Sending error   : \(e.message)")
      } catch {
         log("Unexpected error: ")
      }
      // NOTE: original log format:
      // msg = ret.trimmingCharacters(in: .newlines)
      // msg = msg.isEmpty ? "ERROR" : msg
      // log("Sending error   : \(msg)")
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

      let pathCStr = (Config.sockPath as NSString).utf8String!
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

      log("Socket bound to \(Config.sockPath)")

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
