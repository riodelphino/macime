import Darwin
import Foundation
import XCTest

@testable import MacIMEKit

private struct HarnessError: Error, CustomStringConvertible {
   let description: String
}

private final class DaemonHarness {
   let process = Process()
   let socketPath = "/tmp/macimed-test-\(UUID().uuidString).sock"
   private let stderrPipe = Pipe()

   init() throws {
      process.executableURL = try Self.ExecutableURL()
      process.arguments = ["--log-level", "error"]
      process.environment = ProcessInfo.processInfo.environment.merging(
         ["MACIME_SOCK_PATH": socketPath]
      ) { _, testValue in testValue }
      process.standardOutput = FileHandle.nullDevice
      process.standardError = stderrPipe
      try process.run()

      let deadline = ProcessInfo.processInfo.systemUptime + 3
      while ProcessInfo.processInfo.systemUptime < deadline {
         if FileManager.default.fileExists(atPath: socketPath) {
            return
         }
         if !process.isRunning {
            let stderr = String(
               data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8
            ) ?? ""
            throw HarnessError(description: "macimed exited during startup: \(stderr)")
         }
         usleep(10_000)
      }
      Stop()
      throw HarnessError(description: "macimed socket was not created")
   }

   deinit {
      Stop()
   }

   func Stop() {
      if process.isRunning {
         process.terminate()
         let deadline = ProcessInfo.processInfo.systemUptime + 2
         while process.isRunning && ProcessInfo.processInfo.systemUptime < deadline {
            usleep(10_000)
         }
         if process.isRunning {
            kill(process.processIdentifier, SIGKILL)
         }
         process.waitUntilExit()
      }
      if FileManager.default.fileExists(atPath: socketPath) {
         try? FileManager.default.removeItem(atPath: socketPath)
      }
   }

   func Connect() throws -> Int32 {
      let client = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
      guard client >= 0 else {
         throw HarnessError(description: "socket() failed: errno=\(errno)")
      }

      var noSigPipe: Int32 = 1
      _ = setsockopt(
         client, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe,
         socklen_t(MemoryLayout.size(ofValue: noSigPipe))
      )

      var addr = sockaddr_un()
      addr.sun_family = sa_family_t(AF_UNIX)
      let pathBytes = socketPath.utf8CString
      let pathSize = MemoryLayout.size(ofValue: addr.sun_path)
      guard pathBytes.count <= pathSize else {
         close(client)
         throw HarnessError(description: "socket path exceeds sun_path")
      }
      withUnsafeMutableBytes(of: &addr.sun_path) { buffer in
         for index in pathBytes.indices {
            buffer[index] = UInt8(bitPattern: pathBytes[index])
         }
      }

      let result = withUnsafePointer(to: &addr) {
         $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            Darwin.connect(client, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
         }
      }
      guard result == 0 else {
         let error = errno
         close(client)
         throw HarnessError(description: "connect() failed: errno=\(error)")
      }
      return client
   }

   func Request(_ command: String, timeoutMs: Int = 1_000) throws -> Data {
      let client = try Connect()
      defer { close(client) }
      try SetReceiveTimeout(client, timeoutMs: timeoutMs)
      try SendAll(client, Data(command.utf8))
      _ = shutdown(client, SHUT_WR)
      return try ReadAll(client)
   }

   private static func ExecutableURL() throws -> URL {
      if let path = ProcessInfo.processInfo.environment["MACIMED_TEST_EXECUTABLE"] {
         return URL(fileURLWithPath: path)
      }
      let url = Bundle(for: IMEDSocketTests.self).bundleURL
         .deletingLastPathComponent().appendingPathComponent("macimed")
      guard FileManager.default.isExecutableFile(atPath: url.path) else {
         throw HarnessError(description: "macimed executable not found at \(url.path)")
      }
      return url
   }
}

private func SetReceiveTimeout(_ socket: Int32, timeoutMs: Int) throws {
   var timeout = timeval(
      tv_sec: timeoutMs / 1_000,
      tv_usec: Int32(timeoutMs % 1_000) * 1_000
   )
   guard setsockopt(
      socket, SOL_SOCKET, SO_RCVTIMEO, &timeout,
      socklen_t(MemoryLayout.size(ofValue: timeout))
   ) == 0 else {
      throw HarnessError(description: "SO_RCVTIMEO failed: errno=\(errno)")
   }
}

private func SendAll(_ socket: Int32, _ data: Data) throws {
   try data.withUnsafeBytes { buffer in
      guard let baseAddress = buffer.baseAddress else { return }
      var offset = 0
      while offset < buffer.count {
         let written = Darwin.write(
            socket, baseAddress.advanced(by: offset), buffer.count - offset
         )
         if written > 0 {
            offset += written
         } else if written < 0 && errno == EINTR {
            continue
         } else {
            throw HarnessError(description: "write() failed: errno=\(errno)")
         }
      }
   }
}

private func ReadAll(_ socket: Int32) throws -> Data {
   var result = Data()
   var buffer = [UInt8](repeating: 0, count: 4_096)
   while true {
      let count = Darwin.read(socket, &buffer, buffer.count)
      if count > 0 {
         result.append(contentsOf: buffer[0 ..< count])
      } else if count == 0 {
         return result
      } else if errno != EINTR {
         throw HarnessError(description: "read() failed: errno=\(errno)")
      }
   }
}

final class IMEDSocketTests: XCTestCase {
   func testInterruptedReadRetries() {
      var sockets: [Int32] = [0, 0]
      XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &sockets), 0)
      let server = sockets[0]
      let client = sockets[1]
      defer { close(client) }

      var noSigPipe: Int32 = 1
      XCTAssertEqual(
         setsockopt(
            client, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe,
            socklen_t(MemoryLayout.size(ofValue: noSigPipe))
         ), 0
      )

      var action = sigaction()
      sigemptyset(&action.sa_mask)
      action.sa_flags = 0
      action.__sigaction_u.__sa_handler = { _ in }
      var previousAction = sigaction()
      XCTAssertEqual(sigaction(SIGUSR1, &action, &previousAction), 0)
      defer { _ = sigaction(SIGUSR1, &previousAction, nil) }

      let blockedThread = pthread_self()
      let senderDone = DispatchSemaphore(value: 0)
      DispatchQueue.global().async {
         usleep(50_000)
         _ = pthread_kill(blockedThread, SIGUSR1)
         usleep(50_000)
         let command = Array("daemon get log-level\n".utf8)
         _ = command.withUnsafeBytes {
            Darwin.write(client, $0.baseAddress, $0.count)
         }
         senderDone.signal()
      }

      IMED.handleClient(server)
      XCTAssertEqual(senderDone.wait(timeout: .now() + 1), .success)

      var response = [UInt8](repeating: 0, count: 64)
      let responseCount = Darwin.read(client, &response, response.count)
      XCTAssertGreaterThan(responseCount, 0)
      guard responseCount > 0 else { return }
      XCTAssertEqual(
         String(bytes: response[0 ..< responseCount], encoding: .utf8), Runtime.logLevel.string
      )
   }

   func testIdleClientTimesOut() throws {
      let daemon = try DaemonHarness()
      let blocker = try daemon.Connect()
      defer { close(blocker) }
      try SetReceiveTimeout(blocker, timeoutMs: 1_000)
      var byte: UInt8 = 0
      XCTAssertEqual(Darwin.read(blocker, &byte, 1), 0)
   }

   func testIdleClientDoesNotBlockAnotherRequest() throws {
      let daemon = try DaemonHarness()
      let blocker = try daemon.Connect()
      defer { close(blocker) }
      usleep(50_000)

      let start = ProcessInfo.processInfo.systemUptime
      XCTAssertFalse(try daemon.Request("ime get\n", timeoutMs: 500).isEmpty)
      XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - start, 0.5)
   }

   func testDisconnectedClientDoesNotTerminateDaemon() throws {
      let daemon = try DaemonHarness()
      let blocker = try daemon.Connect()
      usleep(50_000)

      let abandoned = try daemon.Connect()
      var reset = linger(l_onoff: 1, l_linger: 0)
      XCTAssertEqual(
         setsockopt(
            abandoned, SOL_SOCKET, SO_LINGER, &reset,
            socklen_t(MemoryLayout.size(ofValue: reset))
         ), 0
      )
      usleep(50_000)
      try SendAll(abandoned, Data("ime get\n".utf8))
      close(abandoned)
      close(blocker)
      usleep(300_000)

      XCTAssertTrue(daemon.process.isRunning)
      XCTAssertFalse(try daemon.Request("ime get\n").isEmpty)
   }

   func testConcurrentRequestsReturnOneInputSource() throws {
      let daemon = try DaemonHarness()
      let lock = NSLock()
      var responses = [Data]()
      var errors = [Error]()

      DispatchQueue.concurrentPerform(iterations: 200) { _ in
         do {
            let response = try daemon.Request("ime get\n", timeoutMs: 3_000)
            lock.lock()
            responses.append(response)
            lock.unlock()
         } catch {
            lock.lock()
            errors.append(error)
            lock.unlock()
         }
      }

      XCTAssertTrue(errors.isEmpty, "\(errors)")
      XCTAssertEqual(responses.count, 200)
      XCTAssertEqual(Set(responses).count, 1)
      XCTAssertFalse(responses.first?.isEmpty ?? true)
   }

   func testDetailedListResponseIsCompleteJSON() throws {
      let daemon = try DaemonHarness()
      let response = try daemon.Request("ime list --detail\n", timeoutMs: 3_000)
      let json = try JSONSerialization.jsonObject(with: response)
      let sources = try XCTUnwrap(json as? [[String: Any]])
      XCTAssertFalse(sources.isEmpty)
   }
}
