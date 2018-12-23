
import UIKit

extension Int {

    func toString() -> String {
        return String(self)
    }
    
    func toBool() -> Bool {
        if self > 0 {
            return true
        } else {
            return false
        }
    }
    
    init(_ value: Bool) {
        if value {
            self.init(1)
        } else {
            self.init(0)
        }
    }
}
