
import UIKit
import Foundation

extension String {
    
    func heightWithConstrainedWidth(width: CGFloat = CGFloat(MAXFLOAT), font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingRect.height
    }
    
    func widthWithConstrainedHeight(height: CGFloat =  CGFloat(MAXFLOAT), font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        let boundingRect = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingRect.width
    }
}

extension String {
    
    /// 长度
    var length: Int {
        return self.count
    }
    
    func trim(_ shouldTrimNewline: Bool = false) ->String {
        if shouldTrimNewline {
            return self.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    /// 获取子字符串的起始位置
    ///
    /// - Parameter substring: 待查找的子字符串
    /// - Returns: 如果没有匹配的子串, 返回 NSNotFound, 否则返回其所在起始位置
    func location(_ substring: String) -> Int {
        return (self as NSString).range(of: substring).location
    }
    
    /// 根据起始位置和长度获取子字符串
    ///
    /// - Parameters:
    ///   - location: 起始位置
    ///   - length: 长度
    /// - Returns: 如果位置和长度都合理 则返回子字符串, 否则返回 nil
    func substring(_ location: Int, length: Int) -> String? {
        if location < 0 && location >= self.length {
            return nil
        }
        if length <= 0 || length >= self.length {
            return nil
        }
        return (self as NSString).substring(with: NSMakeRange(location, length))
    }
    
    /// 根据下标获取对应的字符
    subscript(index: Int) -> Character? {
        get {
            if let str = substring(index, length: 1) {
                return Character(str)
            }
            return nil
        }
    }
    
    /// 判断是否包含子字符串
    func isContain(_ substring: String) ->Bool {
        return (self as NSString).contains(substring)
    }
    
    /// 判断字符串是否全是数字组成
    func isOnlyNumbers() ->Bool {
        let set = CharacterSet.decimalDigits.inverted
        let range = (self as NSString).rangeOfCharacter(from: set)
        let flag = range.location != NSNotFound
        return flag
    }
    
    /// 判断字符串是否全是字母组成
    func isOnlyLetters() ->Bool {
        let set = CharacterSet.letters.inverted
        let range = (self as NSString).rangeOfCharacter(from: set)
        return range.location != NSNotFound
    }
    
    /// 判断字符串是否全是字母和数字组成
    func isAlphanum() ->Bool {
        let set = CharacterSet.alphanumerics.inverted
        let range = (self as NSString).rangeOfCharacter(from: set)
        return range.location != NSNotFound
    }
    
    /// 判断字符串是否是有效的邮箱格式
    func isValidEmail() ->Bool {
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regEx)
        return predicate.evaluate(with: self)
    }
    
    /// 插入字符分隔字符串
    ///
    /// - Parameters:
    ///   - char: 分隔符
    ///   - interval: 间隔
    /// - Returns: String
    func insertCharByInterval(_ char: String, interval: Int) -> String {
        var text = self as NSString
        var newString = ""
        while (text.length > 0) {
            let subString = text.substring(to: min(text.length,interval))
            newString = newString + subString
            if (subString.length == interval) {
                newString = newString + char
            }
            text = text.substring(from: min(text.length,interval)) as NSString
        }
        return newString
    }
    
    /// 字符串 -> Double
    ///
    /// - Parameters:
    ///   - def: 默认值
    ///   - decimal: 舍弃精度
    /// - Returns: Double
    func toDouble(_ defaultDouble: Double = 0.0, decimal: Int? = nil) -> Double {
        if !self.isEmpty {
            var doubleValue = Double(self) ?? defaultDouble
            if let dec = decimal {
                doubleValue = doubleValue.f(places: dec)
            }
            return doubleValue
        } else {
            return defaultDouble
        }
    }
    
    func toFloat(_ defaultFloat: Float = 0.0) -> Float {
        if !self.isEmpty {
            return Float(self) ?? defaultFloat
        } else {
            return defaultFloat
        }
    }
    
    func toInt(_ defaultInt: Int = 0) -> Int {
        if !self.isEmpty {
            return Int(self)!
        } else {
            return defaultInt
        }
    }
    
    func toBool(_ defaultBool: Bool = false) -> Bool {
        if !self.isEmpty {
            let value = Int(self)!
            if value > 0 {
                return true
            } else {
                return false
            }
        } else {
            return defaultBool
        }
    }
}
