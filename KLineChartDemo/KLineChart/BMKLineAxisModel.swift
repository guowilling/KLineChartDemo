
import Foundation
import UIKit

/// Y 轴显示的位置
///
/// - left: 左边
/// - right: 右边
/// - none: 不显示
public enum BMKLineYAxisShowPosition {
    case left, right, none
}

/// 坐标轴辅助线样式风格
///
/// - none: 不显示
/// - dash: 虚线
/// - solid: 实线
public enum BMKLineAxisReferenceStyle {
    case none
    case dash(color: UIColor, pattern: [NSNumber])
    case solid(color: UIColor)
}

/// Y 轴数据
public struct BMKLineYAxis {
    public var max: CGFloat = 0       // Y 轴的最大值
    public var min: CGFloat = 0       // Y 轴的最小值
    public var ext: CGFloat = 0.0     // 上下边界溢出值的比例
    public var baseValue: CGFloat = 0 // 固定的基值
    public var tickInterval: Int = 4  // 间断显示个数
    public var decimal: Int = 2       // 几位小数
    public var isUsed = false
    public var referenceStyle: BMKLineAxisReferenceStyle = .dash(color: UIColor(white: 0.3, alpha: 1), pattern: [4])
}

/// X 轴数据
public struct BMKLineXAxis {
    public var tickInterval: Int = 6 // 间断显示个数
    public var referenceStyle: BMKLineAxisReferenceStyle = .none
}
