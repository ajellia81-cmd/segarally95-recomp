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
print("Asset-free Metal triangle visible; center pixel verified")
