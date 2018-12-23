
import UIKit

class CHDynamicItem: NSObject, UIDynamicItem {
    var center: CGPoint = .zero
    var bounds: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var transform: CGAffineTransform = CGAffineTransform.identity
}
