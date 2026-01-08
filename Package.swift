// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
   name: "macime",
   platforms: [.macOS(.v13)],
   products: [
      .executable(name: "macime", targets: ["macime"])
   ],
   targets: [
      .executableTarget(
         name: "macime",
         path: "Sources/macime",
         sources: ["main.swift"],
         linkerSettings: [
            .linkedFramework("Foundation"),
            .linkedFramework("InputMethodKit"),
         ]
      )
   ]
)
