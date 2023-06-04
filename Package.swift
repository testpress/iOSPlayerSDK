// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TPStreamsSDK",
  platforms: [
    .iOS(.v14),
  ],
  products: [
    .library(
      name: "TPStreamsSDK",
      targets: ["TPStreamsSDK"])
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0"))
  ],

  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "TPStreamsSDK",
      dependencies: [
        "Alamofire"
      ],
      path: "Source"
      ),
    .testTarget(
      name: "iOSPlayerSDKTests",
      dependencies: ["TPStreamsSDK"],
      path:"Tests")
  ],  
  swiftLanguageVersions: [
    .v5
  ]
)