// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "RealtimeKitUI",
  platforms: [.iOS(.v13)],
  products: [
    .library(name: "RealtimeKitUI", targets: ["RealtimeKitUI"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/dyte-in/RealtimeKitiOS.git",
      revision: "6e8c2238626499516c2a278344c42802b184b1ff")
  ],
  targets: [
    .target(
      name: "RealtimeKitUI",
      path: "RealtimeKitUI/",
      dependencies: [
        "RealtimeKit",
        "DyteWebRTC",
      ],
      resources: [
        .process("Resources/notification_join.mp3"),
        .process("Resources/notification_message.mp3"),
      ])
  ]
)
