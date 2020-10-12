import UIKit

extension UIView {

    func fadeIn() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
    }

    func fadeOut() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
        }
    }
}