import Foundation
import UIKit

extension ViewController {
    // MARK: - Bounding box drawing
    
    // Draw a box on screen. Must be called from main queue.
    // Bounding boxes are not nice may be because of videogravity or zone of interest frame - need to check it
    
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 1
        layer.borderColor = color
        layer.borderWidth = 1
        layer.frame = rect
        layer.fillColor = color
        layer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)))

        previewLayer.insertSublayer(layer, at: 1)
        guard
            let sublayers = previewLayer.sublayers else { return }
        if sublayers.count > 2 {
            previewLayer.sublayers?.removeLast()
        }
    }
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    
    // Draws groups of colored boxes.
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.previewLayer
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
}
