import Foundation

public enum IMED {
   public static var state: IMEDState!

   public static func setState(_ newState: IMEDState) {
      state = newState
   }

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
   public static func execute(_ cmd: String) throws -> IMEDResult {
      var args = ArgsCommon.splitArgs(cmd)
      guard args.count > 0 else {
         throw AppError.imed(.invalidDaemonMethod("nil"))
      }
      var methodStr = args.removeFirst()

      var stdout = ""
      // var stderr = "" // stderr is modified only by AppError.

      // (Backward compatibility) Add `ime` if methodStr is missing. (`macime.nvim` < v3.0.0) // TODO: Remove this in later version
      switch methodStr {
      case "ime", "daemon":
         break
      default: // set, get, load, e.t.c. -> Fallback to `ime` method
         let subcmd = methodStr
         methodStr = "ime"
         args.insert(subcmd, at: 0) // Insert subcmd back to the head of args
         Log.warn("Missing IMED method. Fallback to 'ime' method")
      }
      let method = try IMEDMethod(methodStr)

      switch method {
      case .ime:
         let imeState = try IMEArgs.parse(args)
         let ret = try IME.execute(imeState) ?? ""
         stdout = ret

      case .daemon:
         let subcmdStr = args.removeFirst()
         let subcmd = try IMEDSubCmd(subcmdStr)

         switch subcmd {
         case .info:
            let json: [String: Any] = ["status": state.status ?? "", "sock-path": state.sockPath ?? ""]
            stdout = try Util.jsonToString(json, options: [.withoutEscapingSlashes])
         case .get:
            guard args.count > 0 else {
               throw AppError.imed(.invalidGetTarget("nil"))
            }
            let target = args.removeFirst()
            switch target {
            case "sock-path":
               stdout = state.sockPath ?? ""
            case "log-level":
               stdout = Runtime.logLevel.string
            default:
               throw AppError.imed(.invalidGetTarget(target))
            }
         case .set:
            let target = args.removeFirst()
            switch target {
            case "log-level":
               guard args.count > 0 else {
                  throw AppError.imed(.missingLogLevel)
               }
               let logLevelStr = args.first ?? ""
               guard let logLevel = LogLevel(logLevelStr) else {
                  throw AppError.imed(.invalidLogLevel(logLevelStr))
               }
               Runtime.logLevel = logLevel
               stdout = "Log level set to: \(logLevelStr)"
            default:
               throw AppError.imed(.invalidSetTarget(target))
            }
         }
      }

      return IMEDResult(stdout: stdout, stderr: "")
   }

   /// Handles a single connected client socket
   public static func handleClient(_ client: Int32) {
      defer { close(client) }

      Log.info("Client connected: fd=\(client)")

      var buffer = [UInt8](repeating: 0, count: 4096)
      let bytesRead = read(client, &buffer, buffer.count)

      guard bytesRead > 0 else {
         Log.error("Client read failed or EOF")
         return
      }

      let command =
         String(bytes: buffer[0 ..< bytesRead], encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines
         ) ?? ""

      Log.info("Recieved command: \(command)")

      do {
         let ms = try Util.elapsed {
            let ret: IMEDResult = try self.execute(command)

            switch ret {
            case var .success(stdout):
               stdout = stdout.isEmpty ? "OK" : stdout
               write(client, stdout, strlen(stdout)) // Write stdout
               Log.info("Client response : \(stdout)")
            case let .failure(stderr):
               write(client, stderr, strlen(stderr)) // Write stderr
               Log.error("Client error    : \(stderr)")
            }

            shutdown(client, SHUT_WR)
         }
         Log.info("Elapsed time    : \(ms)ms")
         return
      } catch let e as AppError {
         Log.error("Executing error : \(e.message)")
      } catch {
         Log.error("Unexpected error: ")
      }
   }

   /// Starts the IMED daemon and begins accepting client connections.
   public static func serve() throws {
      _ = cleanupSocket()

      let fd = socket(AF_UNIX, SOCK_STREAM, 0)
      guard fd >= 0 else {
         throw NSError(domain: "socket", code: -1, userInfo: ["msg": "socket() failed"])
      }

      Log.info("Socket created: fd=\(fd)")

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

      Log.info("Socket bound to \(state.sockPath ?? "")")

      guard listen(fd, 5) == 0 else {
         throw NSError(domain: "listen", code: -1, userInfo: ["msg": "listen() failed"])
      }

      Log.info("Listening for connections...")

      while true {
         let client = accept(fd, nil, nil)
         guard client >= 0 else {
            Log.error("accept() failed")
            continue
         }
         DispatchQueue.global().async {
            self.handleClient(client)
         }
      }
   }
}
