
import Foundation
import UIKit

public extension CGFloat {
    
    func bm_toString(_ minF: Int = 2, maxF: Int = 6, minI: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = minF
        formatter.maximumFractionDigits = maxF
        formatter.minimumIntegerDigits = minI
        let decimalNumber = NSDecimalNumber(value: Double(self))
        return formatter.string(from: decimalNumber)!
    }
}

public extension String {
    
    func bm_sizeWithConstrained(_ font: UIFont, constraintRect: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) -> CGSize {
        let boundingRect = self.boundingRect(
            with: constraintRect,
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil
        )
        return boundingRect.size
    }
    
    var bm_length: Int {
        return self.count
    }
}

public extension UIColor {
    
    class func bm_hex(_ hex: UInt, alpha: Float = 1.0) -> UIColor {
        return UIColor(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }
    
    class func bm_hexString(_ hexString: String, alpha: CGFloat = 1.0) -> UIColor {
        let scanner = Scanner(string: hexString)
        scanner.scanLocation = 0
        var hexUInt: UInt64 = 0
        scanner.scanHexInt64(&hexUInt)
        return UIColor.bm_hex(UInt(hexUInt))
    }
}

public extension Date {
    /// 时间戳转换为用户格式时间
    ///
    /// - Parameters:
    ///   - timestamp: 时间戳
    ///   - format: 格式
    /// - Returns: 时间字符串
    static func bm_timeStringOfStamp(_ timestamp: Int, format: String) -> String {
        if timestamp == 0 {
            return ""
        }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

public extension Array where Element: Equatable {
    
    subscript (safe index: Int) -> Element? {
        return (0..<count).contains(index) ? self[index] : nil
    }
    
    mutating func bm_removeObject(_ object: Element) {
        if let index = self.firstIndex(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func bm_removeObjectsInArray(_ array: [Element]) {
        for object in array {
            self.bm_removeObject(object)
        }
    }
}
