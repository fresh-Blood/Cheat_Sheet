import Foundation
import UIKit


extension ViewController {
    func setButtonGesturePolitics() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(tapRecognizeButton))
        gesture.minimumPressDuration = 0
        recognizeButton.addGestureRecognizer(gesture)
    }
    @objc private func tapRecognizeButton(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            recognizeButton.alpha = 0.5
            createObjectDetectionVisionRequest()
        } else {
            recognizeButton.alpha = 1.0
        }
    }
}
