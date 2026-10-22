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
let viewportWidth = min(Double(image.pixelsWide), Double(image.pixelsHigh) * 4.0 / 3.0)
let textureX = image.pixelsWide / 2 + Int(viewportWidth * 180.0 / 496.0)
guard let textureColor = image.colorAt(x: textureX, y: image.pixelsHigh / 2)?.usingColorSpace(.deviceRGB),
      textureColor.greenComponent > 0.8 && textureColor.redComponent < 0.3 && textureColor.blueComponent < 0.3 else {
    fatalError("Synthetic textured triangle/edge clamp did not match expected green pixel")
}
print("Asset-free Metal solid and textured triangles visible; center and edge-clamp pixels verified")
