import AppKit
import Foundation
let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
guard let image = NSBitmapImageRep(data: data) else { fatalError("Cannot read simulator screenshot") }
let layoutData = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
let layout = try JSONSerialization.jsonObject(with: layoutData) as! [String: Any]
guard layout["valid"] as? Bool == true, layout["controllerPolicy"] as? Bool == true else {
    fatalError("Safe-area layout or controller hide/restore policy failed: \(layout)")
}
let bounds = layout["bounds"] as! [Double], viewport = layout["viewport"] as! [Double]
let drawable = layout["drawable"] as! [Double], scale = layout["scale"] as! Double
guard bounds[0] > bounds[1], drawable[0] > 0, drawable[1] > 0, scale >= 1 else {
    fatalError("Invalid landscape/native drawable geometry: \(layout)")
}
let center = (viewport[0] + viewport[2]/2, viewport[1] + viewport[3]/2)
let texture = (center.0 + viewport[2]*180.0/496.0, center.1)
let width = image.pixelsWide, height = image.pixelsHigh
// simctl screenshots may keep the portrait pixel orientation. Transform both
// expected fixture points together; the two colors must match one orientation.
func pixel(_ point: (Double, Double), _ rotation: Int) -> NSColor? {
    let (x, y) = point
    let px: Double, py: Double
    switch rotation {
    case 0: px = x/bounds[0]; py = y/bounds[1]
    case 1: px = 1-x/bounds[0]; py = 1-y/bounds[1]
    case 2: px = 1-y/bounds[1]; py = x/bounds[0]
    default: px = y/bounds[1]; py = 1-x/bounds[0]
    }
    let ix = Int(px*Double(width)), iy = Int(py*Double(height))
    guard ix >= 0, ix < width, iy >= 0, iy < height else { return nil }
    return image.colorAt(x: ix, y: iy)?.usingColorSpace(.deviceRGB)
}
var matched = false
var diagnostics: [String] = []
for rotation in width >= height ? [0, 1] : [2, 3] {
    guard let red = pixel(center, rotation), let green = pixel(texture, rotation) else { continue }
    diagnostics.append("rotation \(rotation): center=\(red), texture=\(green)")
    matched = matched || (red.redComponent > 0.8 && red.greenComponent < 0.3 && red.blueComponent < 0.3
        && green.greenComponent > 0.8 && green.redComponent < 0.3 && green.blueComponent < 0.3)
}
guard matched else { fatalError("Synthetic Metal pixel mismatch: \(diagnostics); layout=\(layout)") }
print("Asset-free Metal solid/texture pixels, safe-area native layout and touch hide/restore policy verified (\(width)x\(height), drawable=\(drawable), scale=\(scale))")
