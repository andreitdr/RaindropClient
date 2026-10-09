// swift-tools-version: 5.9
import PackageDescription

// The sources are shared with the other Apple platform: this package's
// `Sources` is a symlink to `../../darwin/Sources`, so the Objective-C exists
// once. Only the platform minimum and the Flutter framework differ.
let package = Package(
    name: "raindrop_camera_effects",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "raindrop-camera-effects", targets: ["raindrop_camera_effects"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Resolved by the Flutter tool to the flutter_webrtc plugin package.
        // Nothing is forked: this depends on flutter_webrtc's published package
        // and uses only its public headers.
        .package(name: "flutter_webrtc", path: "../flutter_webrtc")
    ],
    targets: [
        .target(
            name: "raindrop_camera_effects",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                // FlutterWebRTCPlugin and LocalVideoTrack.
                .product(name: "flutter-webrtc", package: "flutter_webrtc"),
                // RTCVideoFrame and the I420 buffers. Taken from flutter_webrtc's
                // re-exported product rather than declared again, so there is one
                // copy of the binary framework in the app.
                .product(name: "WebRTC", package: "flutter_webrtc")
            ],
            cSettings: [
                .headerSearchPath("include/raindrop_camera_effects")
            ]
        )
    ]
)
