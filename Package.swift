// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// TODO: 5.5 ??

import PackageDescription

let package = Package(
   name: "macime",
   platforms: [
      .macOS(.v13)
      // TODO: .macOS(.v10_15) ?
   ],
   products: [
      .executable(name: "macime", targets: ["macime"]),
      .executable(name: "macimed", targets: ["macimed"]),
   ],
   targets: [
      // Shared library with common logic
      .target(
         name: "MacIMEKit",
         dependencies: [],
         path: "Sources/MacIMEKit"
      ),

      // macime CLI tool
      .executableTarget(
         name: "macime",
         dependencies: ["MacIMEKit"],
         path: "Sources/macime"
      ),

      // macimed daemon
      .executableTarget(
         name: "macimed",
         dependencies: ["MacIMEKit"],
         path: "Sources/macimed",
         resources: [
            .copy("Resources/com.riodelphino.macimed.plist")
         ]
      ),
   ]
)
