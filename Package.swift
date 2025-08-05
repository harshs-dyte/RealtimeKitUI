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
      url: "https://github.com/dyte-in/RealtimeKitCoreiOS.git",
      revision: "aeb83f855f18d8f601e289d542958755683bcae3")
  ],
  targets: [
    .target(
      name: "RealtimeKitUI",
      path: "RealtimeKitUI/",
      dependencies: [
        "RealtimeKit",
        "RTKWebRTC",
      ],
      resources: [
        .process("Resources/notification_join.mp3"),
        .process("Resources/notification_message.mp3"),
      ])
  ]
)
