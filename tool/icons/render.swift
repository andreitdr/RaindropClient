import AppKit
import UniformTypeIdentifiers

// Rasterises an SVG with AppKit's own renderer.
// Usage: render <in.svg> <out.png> <size> [opaque]
// "opaque" writes RGB with no alpha channel, which the App Store requires of the iOS icon.
func fail(_ message: String) -> Never {
  FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
  exit(1)
}

let args = CommandLine.arguments
guard args.count >= 4, let size = Int(args[3]) else { fail("usage: render <in.svg> <out.png> <size> [opaque]") }
let opaque = args.count > 4 && args[4] == "opaque"
guard let image = NSImage(contentsOfFile: args[1]) else { fail("cannot read \(args[1])") }

let alpha: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
guard let cg = CGContext(
  data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: alpha.rawValue)
else { fail("cannot create a \(size)px context") }
cg.interpolationQuality = .high
if opaque {
  cg.setFillColor(CGColor(gray: 0, alpha: 1))
  cg.fill(CGRect(x: 0, y: 0, width: size, height: size))
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)
image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
NSGraphicsContext.restoreGraphicsState()

let url = URL(fileURLWithPath: args[2]) as CFURL
guard let out = cg.makeImage(),
  let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)
else { fail("cannot write \(args[2])") }
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else { fail("cannot write \(args[2])") }
