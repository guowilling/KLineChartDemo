
import Foundation

extension Double {
    /// 向下取几位小数
    ///
    /// - Parameter places: 1
    /// - Returns: 15.96 -> 15.9
    func f(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return floor(self * divisor) / divisor
        // 15.96 向下取1位小数
        // 15.96 * 10.0 = 159.6
        // floor(159.6) = 159.0
        // 159.0 / 10.0 = 15.9
    }
    
    func toFloor(_ places: Int) -> String {
        let divisor = pow(10.0, Double(places))
        return (floor(self * divisor) / divisor).toString(maxF: places)
    }
    
    func toString(_ minF: Int = 0, maxF: Int = 10, minI: Int = 1) -> String {
        let decimalNumber = NSDecimalNumber(value: self)
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = minF
        formatter.maximumFractionDigits = maxF
        formatter.minimumIntegerDigits = minI
        return formatter.string(from: decimalNumber)!
    }
    
    /// 除法
    ///
    /// - Parameters:
    ///   - divisor: 除数
    ///   - dec: 保留小数位
    /// - Returns: String
    func divideResultToString(divisor: Double?, dec: Int = 3) -> String {
        guard let divisor = divisor, divisor != 0, self != 0 else {
            return ""
        }
        return String(format: "%.\(dec)f", self / divisor)
    }
    
    /// 乘法
    ///
    /// - Parameters:
    ///   - multi: 乘数
    ///   - dec: 保留小数位
    /// - Returns: String
    func multiplyResultToString(multiplier: Double?, dec: Int = 3) -> String{
        guard let multi = multiplier, self != 0, multi != 0 else {
            return ""
        }
        return String(format: "%.\(dec)f", self * multi)
    }
    
    func toNonZeroString(_ replace: String = "", minF: Int = 0, maxF: Int = 10, minI: Int = 1) -> String {
        if self == 0 {
            return replace
        } else {
            return toString(minF, maxF: maxF, minI: minI)
        }
    }
}

extension Double {
    
    func formatPrice() -> String {
        var formatPriceStr = ""
        let absValue = fabs(self)
        if absValue > 100 {
            formatPriceStr = String(format: "%.2f", self)
        } else if absValue > 0.1 {
            formatPriceStr = String(format: "%.4f", self)
        } else if absValue > 0.001 {
            formatPriceStr = String(format: "%.6f", self)
        } else {
            formatPriceStr = String(format: "%.8f", self)
        }
        return formatPriceStr
    }
    
    func formatAmount() -> String {
        var formatAmountStr = ""
        if self > 1000000 {
            formatAmountStr = String(format: "%.2f万", self / 10000)
        } else {
            formatAmountStr = String(format: "%.2f", self)
        }
        return formatAmountStr
    }
}
