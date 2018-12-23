
import Foundation

extension Date {
    
    static func getTimeByStamp(timestamp: Int, format: String) -> String {
        if timestamp == 0 {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let date = NSDate(timeIntervalSince1970: TimeInterval(timestamp))
        return formatter.string(from: date as Date)
    }
    
    static func getTimeDescribeByStamp(timestamp: Int) -> String {
        let compareDate = NSDate(timeIntervalSince1970: TimeInterval(timestamp))
        var timeInterval: Double = compareDate.timeIntervalSinceNow
        timeInterval = -timeInterval;
        var tempInterval: Double = 0;
        var result = ""
        if timeInterval < 60 {
            result = "刚刚"
        } else if (timeInterval / 60) < 60 {
            tempInterval = timeInterval / 60
            result = "\(Int(tempInterval))分钟前"
        } else if (timeInterval / 60 / 60) < 24 {
            tempInterval = timeInterval / 60 / 60
            result = "\(Int(tempInterval))小时前"
        } else if (timeInterval / 60 / 60 / 24) < 30 {
            tempInterval = timeInterval / 60 / 60 / 24
            result = "\(Int(tempInterval))天前"
        } else if (timeInterval / 60 / 60 / 24 / 30) < 12 {
            tempInterval = timeInterval / 60 / 60 / 24 / 30
            result = "\(Int(tempInterval))个月前"
        } else {
            tempInterval = timeInterval / 60 / 60 / 24 / 30 / 12
            result = "\(Int(tempInterval))年前"
        }
        return result
    }
}
