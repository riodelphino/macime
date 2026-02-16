import Foundation

public var state = IMEDCmdState()

public enum IMED {
   /// Clean up the socket
   public static func cleanupSocket() -> Bool {
      return FS.removePath(state.sockPath ?? "")
   }

   /// Check whether macime already running
   public static func isMacimedRunning(sockPath: String) -> Bool {
      let fd = socket(AF_UNIX, SOCK_STREAM, 0)
      guard fd >= 0 else { return false }
      defer { close(fd) }

      var addr = sockaddr_un()
      addr.sun_family = sa_family_t(AF_UNIX)

      let pathBytes = sockPath.utf8CString
      withUnsafeMutableBytes(of: &addr.sun_path) { buffer in
         for i in 0 ..< min(buffer.count, pathBytes.count) {
            buffer[i] = UInt8(pathBytes[i])
         }
      }

      let len = socklen_t(MemoryLayout.size(ofValue: addr))
      let result = withUnsafePointer(to: &addr) {
         $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            connect(fd, $0, len)
         }
      }

      return result == 0
   }

   /// Executes a macime command and returns its output
   public static func execute(_ cmd: String) throws -> (String, String) {
      var args = ArgsCommon.splitArgs(cmd)
      guard args.count > 0 else {
         throw AppError.imed(.invalidDaemonMethod("nil"))
      }
      var method = args.removeFirst()

      var stdout = ""
      var stderr = "" // if stderr != "" -> error

      // Backward compatibility (`macime.nvim` < v3.0.0) // TODO: Remove this in later version
      switch method {
      case "ime", "daemon":
         break
      default: // set, get, load, e.t.c. -> Fallback to `ime` method
         let subcmd = method
         method = "ime"
         args.insert(subcmd, at: 0)
      }

      switch method {
      case "ime":
         let imeState = try ArgsIME.parse(args)
         let ret = try IME.execute(imeState)
         stdout = ret
         stderr = "" // DEBUG: Should check success or not, then assort ret to stdout/stderr.

      case "daemon":
         let subcmd = args.removeFirst()
         switch subcmd {
         case "info":
            let json: [String: Any] = ["status": state.status ?? "", "sock-path": state.sockPath ?? "", "macime-path": state.macimePath ?? ""]
            stdout = try Util.jsonToString(json, options: [.withoutEscapingSlashes])
         case "get":
            guard args.count > 0 else {
               throw AppError.imed(.invalidGetTarget("nil"))
            }
            let target = args.removeFirst()
            switch target {
            case "sock-path":
               stdout = state.sockPath ?? ""
            case "macime-path":
               stdout = state.macimePath ?? ""
            default:
               throw AppError.imed(.invalidGetTarget(target))
            }
         default:
            throw AppError.imed(.invalidDaemonSubcmd(subcmd))
         }

      default:
         throw AppError.imed(.invalidDaemonMethod(method))
      }

      return (stdout: stdout, stderr: stderr)
   }

   /// Handles a single connected client socket
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
         String(bytes: buffer[0 ..< bytesRead], encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines
         ) ?? ""

      Log.log("Recieved command: \(command)")

      var stdout = ""
      var stderr = ""

      do {
         let ms = try Util.elapsed {
            // (stdout, stderr) = try self.execute(command)
            try DispatchQueue.main.sync { // DEBUG: Cannot get stdout/stderr
               (stdout, stderr) = try self.execute(command)
            }

            stdout = stdout.trimmingCharacters(in: .newlines)
            stderr = stderr.trimmingCharacters(in: .newlines)

            if stderr.isEmpty {
               stdout = stdout.isEmpty ? "OK" : stdout
               write(client, stdout, strlen(stdout)) // Write stdout
               Log.log("Client response : \(stdout)")
            } else {
               write(client, stderr, strlen(stderr)) // Write stderr
               Log.log("Client error    : \(stderr)")
            }

            shutdown(client, SHUT_WR)
         }
         Log.log("Elapsed time    : \(ms)ms")
         return
      } catch let e as AppError {
         Log.log("Executing error : \(e.message)")
      } catch {
         Log.log("Unexpected error: ")
      }
   }

   /// Starts the IMED daemon and begins accepting client connections.
   public static func serve() throws {
      _ = cleanupSocket()

      let fd = socket(AF_UNIX, SOCK_STREAM, 0)
      guard fd >= 0 else {
         throw NSError(domain: "socket", code: -1, userInfo: ["msg": "socket() failed"])
      }

      Log.log("Socket created: fd=\(fd)")

      defer { close(fd) }

      var addr = sockaddr_un()
      addr.sun_family = sa_family_t(AF_UNIX)

      let pathCStr = ((state.sockPath ?? "") as NSString).utf8String!
      strncpy(
         &addr.sun_path.0, pathCStr,
         MemoryLayout.size(ofValue: addr.sun_path) - 1
      )

      let bindResult = withUnsafePointer(to: &addr) { ptr in
         ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
            bind(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
         }
      }

      guard bindResult == 0 else {
         throw NSError(domain: "bind", code: -1, userInfo: ["msg": "bind() failed"])
      }

      Log.log("Socket bound to \(state.sockPath ?? "")")

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
