// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Personal Signature",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Personal Signature",
            path: "PersonalSignature",
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/AppIcon.icns"),
                .process("Resources/MenuBarIconTemplate.png"),
                .process("Resources/OriginalLogo.png")
            ]
        )
    ]
)
