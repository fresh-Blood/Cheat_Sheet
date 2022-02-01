import Foundation
import UIKit


extension TextViewController {
    func setGoButtonGesturePolitics() {
        let gesture = UILongPressGestureRecognizer(target: self,
                                                   action: #selector(pressGoButton))
        gesture.minimumPressDuration = 0
        goButton.addGestureRecognizer(gesture)
    }
    @objc private func pressGoButton(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            goButton.alpha = 0.5
        } else {
            goButton.alpha = 1
        }
    }
}
