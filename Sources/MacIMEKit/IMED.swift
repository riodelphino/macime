import Foundation

public struct IMED {

   // Clean up the socket
   public static func cleanupSocket() -> Bool {
      return File.removePath(Config.sockPath)
   }

   // Executes a macime command and returns its output
   public static func execute(_ cmd: String) throws -> (String, String) {

      // -- UNFORTUNATELY, `TISInputSource` CANNOT GET/SET the IME OF FRONT APP FROM DAEMON SERVICE --
      //
      // It always returns the default `com.apple.keylayout.ABC`.
      // See:
      //   - https://stackoverflow.com/questions/26612735/os-x-how-to-get-tisinputsourceref-keyboard-layout-of-current-active-window-of
      //   - https://leopard-adc.pepas.com/documentation/TextFonts/Reference/TextInputSourcesReference/TextInputSourcesReference.pdf?utm_source=chatgpt.com
      //
      // -- SO, THE FOLLOWING CODE NOT WORKS --
      // let args = ArgsCommon.splitArgs(cmd)
      // let state: CmdState = ArgsDaemon.parse(args)
      // let response: Response = IMECore.execute(state)
      // return response
      //

      let args = ArgsCommon.splitArgs(cmd)

      let process = Process()
      let outPipe = Pipe()
      let errPipe = Pipe()

      process.executableURL = URL(fileURLWithPath: Config.macimePath)
      process.arguments = args
      process.standardOutput = outPipe
      process.standardError = errPipe

      try process.run()
      process.waitUntilExit()

      let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
      let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
      guard let stdout = String(data: outData, encoding: .utf8) else {
         throw AppError.imed(.dataNotRecieved)
      }
      guard let stderr = String(data: errData, encoding: .utf8) else {
         throw AppError.imed(.dataNotRecieved)
      }
      return (stdout: stdout, stderr: stderr)
   }

   // Handles a single connected client socket
   public static func handleClient(_ client: Int32) {
      defer { close(client) }

      Log.log("Client connected: fd=\(client)")

      var buffer = [UInt8](repeating: 0, count: 4096)
      let bytesRead = read(client, &buffer, buffer.count)

      guard bytesRead > 0 else {
         Log.log("Client read failed or EOF")
         return
      }

      let command =
         String(bytes: buffer[0..<bytesRead], encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines) ?? ""

      Log.log("Received command: \(command)")

      var stdout: String = ""
      var stderr: String = ""

      do {
         let ms = try Util.elapsed {
            (stdout, stderr) = try self.execute(command)
         }

         stdout = stdout.trimmingCharacters(in: .newlines)
         stderr = stderr.trimmingCharacters(in: .newlines)

         stdout = (stderr.isEmpty && stdout.isEmpty) ? "OK" : stdout
         Log.log("Client response : \(stdout)")

         if !stderr.isEmpty {
            Log.log("Client error    : \(stderr)")
         }

         Log.log("Elapsed time    : \(ms)ms")

         // let _ = write(client, stdout, stdout.count)  // Meaningless: The client(macime) are not listening any socket.
         shutdown(client, SHUT_WR)
         return
      } catch let e as AppError {
         Log.log("Executing error : \(e.message)")
      } catch {
         Log.log("Unexpected error: ")
      }
   }

   // Starts the IMED daemon and begins accepting client connections.
   public static func serve() throws {
      guard File.pathExists(Config.macimePath) else {
         throw AppError.imed(.macimeNotFound(Config.macimePath))
      }

      let _ = self.cleanupSocket()

      let fd = socket(AF_UNIX, SOCK_STREAM, 0)
      guard fd >= 0 else {
         throw NSError(domain: "socket", code: -1, userInfo: ["msg": "socket() failed"])
      }

      Log.log("Socket created: fd=\(fd)")

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

      Log.log("Socket bound to \(Config.sockPath)")

      guard listen(fd, 5) == 0 else {
         throw NSError(domain: "listen", code: -1, userInfo: ["msg": "listen() failed"])
      }

      Log.log("Listening for connections...")

      while true {
         let client = accept(fd, nil, nil)
         guard client >= 0 else {
            Log.log("accept() failed")
            continue
         }

         DispatchQueue.global().async {
            self.handleClient(client)
         }
      }
   }

}
