import AppKit
import Foundation
let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
guard let image = NSBitmapImageRep(data: data),
      let color = image.colorAt(x: image.pixelsWide / 2, y: image.pixelsHigh / 2)?.usingColorSpace(.deviceRGB) else {
    fatalError("Cannot read simulator screenshot")
}
guard color.redComponent > 0.8 && color.greenComponent < 0.3 && color.blueComponent < 0.3 else {
    fatalError("Synthetic Metal triangle was not rendered at center: \(color)")
}
// simctl may retain the device's portrait pixel orientation for a landscape app.
// Check the same camera-space point after either supported landscape rotation.
let width = image.pixelsWide, height = image.pixelsHigh
let landscapeWidth = Double(max(width, height))
let landscapeHeight = Double(min(width, height))
let viewportWidth = min(landscapeWidth, landscapeHeight * 4.0 / 3.0)
let offset = Int(viewportWidth * 180.0 / 496.0)
let points = width >= height
    ? [(width / 2 + offset, height / 2), (width / 2 - offset, height / 2)]
    : [(width / 2, height / 2 + offset), (width / 2, height / 2 - offset)]
var matched = false
var diagnostics: [String] = []
for (x, y) in points {
    guard let pixel = image.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
    diagnostics.append("(\(x),\(y)): \(pixel)")
    matched = matched || (pixel.greenComponent > 0.8 && pixel.redComponent < 0.3 && pixel.blueComponent < 0.3)
}
guard matched else {
    fatalError("Synthetic texture/edge clamp mismatch in \(width)x\(height): \(diagnostics)")
}
print("Asset-free Metal solid and textured triangles visible; center and edge-clamp pixels verified (\(width)x\(height))")
