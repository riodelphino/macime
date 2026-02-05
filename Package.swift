// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
   name: "macime",
   platforms: [
      .macOS(.v10_15),
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
         path: "Sources/macimed"
      ),
   ]
)
