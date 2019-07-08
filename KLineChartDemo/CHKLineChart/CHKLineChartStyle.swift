
import Foundation
import UIKit

/// 最大最小值显示风格
///
/// - none: 不显示
/// - arrow: 箭头
/// - circle: 空心圆
/// - tag: 标签
public enum CHUltimateValueStyle {
    case none
    case arrow(UIColor)
    case circle(UIColor, Bool)
    case tag(UIColor)
}

// MARK: - 图表样式类
open class CHKLineChartStyle {
    
    /// 分区样式
    open var sections: [CHSection] = [CHSection]()
    
    /// 支持的指标算法
    open var algorithms: [CHChartAlgorithmProtocol] = [CHChartAlgorithmProtocol]()
    
    /// 背景颜色
    open var backgroundColor: UIColor = UIColor.white
    
    /// 显示边线宽度上左下右
    open var borderWidth: (top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) = (0.5, 0.5, 0.5, 0.5)
    
    /// 边距
    open var padding: UIEdgeInsets!
    
    /// 字体大小
    open var labelFont: UIFont!
    
    /// 边框线条颜色
    open var lineColor: UIColor = UIColor.clear
    
    /// XY 轴上 Label 颜色
    open var textColor: UIColor = UIColor.clear
    
    /// 是否显示选中的内容
    open var showSelection: Bool = true
    
    /// 选中点显示的背景颜色
    open var selectedBGColor: UIColor = UIColor.clear
    
    /// 选中点时显示的 XY 轴上 Label 颜色
    open var selectedTextColor: UIColor = UIColor.clear
    
    /// Y 轴的位置, 默认右边
    open var yAxisShowPosition = CHYAxisShowPosition.right
    
    /// Y 轴是否内嵌到图表里
    open var isInnerYAxis: Bool = false
    
    /// 是否支持缩放
    open var enablePinch: Bool = true
    /// 是否支持滑动
    open var enablePan: Bool = true
    /// 是否支持点选
    open var enableTap: Bool = true
    
    /// X 轴的内容显示到哪个分区上, 默认为-1, 表示最后一个分区, 如果用户设置的值溢出了, 也是最后一个分区
    open var showXAxisOnSection: Int = -1
    
    /// 是否显示 X 轴标签
    open var showXAxisLabel: Bool = true
    
    /// 是否显示所有内容
    open var isShowAll: Bool = false
    
    public init() {}
}

public extension CHKLineChartStyle {
    
    /// 基本图表样式
    static var base: CHKLineChartStyle {
        let style = CHKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor(white: 0.2, alpha: 1)
        style.textColor = UIColor(white: 0.8, alpha: 1)
        style.selectedBGColor = UIColor(white: 0.4, alpha: 1)
        style.selectedTextColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        style.padding = UIEdgeInsets(top: 32, left: 8, bottom: 4, right: 0)
        style.backgroundColor = UIColor.ch_hex(0x1D1C1C)
        style.yAxisShowPosition = .right
        
        style.algorithms = [
            CHChartAlgorithm.timeline,
            CHChartAlgorithm.sar(4, 0.02, 0.2), // 默认周期4, 最小加速0.02, 最大加速0.2
            CHChartAlgorithm.ma(5),
            CHChartAlgorithm.ma(10),
            CHChartAlgorithm.ma(20),            // 计算 BOLL, 必须先计算同周期的 MA
            CHChartAlgorithm.ma(30),
            CHChartAlgorithm.ema(5),
            CHChartAlgorithm.ema(10),
            CHChartAlgorithm.ema(12),           // 计算 MACD, 必须先计算同周期的 EMA
            CHChartAlgorithm.ema(26),           // 计算 MACD, 必须先计算同周期的 EMA
            CHChartAlgorithm.ema(30),
            CHChartAlgorithm.boll(20, 2),
            CHChartAlgorithm.macd(12, 26, 9),
            CHChartAlgorithm.kdj(9, 3, 3),
        ]
        
        let upcolor = (UIColor.ch_hex(0xF80D1F), true)
        let downcolor = (UIColor.ch_hex(0x1E932B), true)
        let priceSection = CHSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.titleShowOutSide = true
        priceSection.valueType = .master
        priceSection.key = "master"
        priceSection.hidden = false
        priceSection.ratios = 3
        priceSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        
        /// 时分线
        let timelineSeries = CHSeries.getTimelinePrice(
            color: UIColor.ch_hex(0xAE475C),
            section: priceSection,
            showGuide: true,
            ultimateValueStyle: .circle(UIColor.ch_hex(0xAE475C), true),
            lineWidth: 2)
        timelineSeries.hidden = true
        
        /// 蜡烛线
        let priceSeries = CHSeries.getCandlePrice(
            upStyle: upcolor,
            downStyle: downcolor,
            titleColor: UIColor(white: 0.8, alpha: 1),
            section: priceSection,
            showGuide: true,
            ultimateValueStyle: .arrow(UIColor(white: 0.8, alpha: 1)))
        priceSeries.showTitle = true
        priceSeries.chartModels.first?.ultimateValueStyle = .arrow(UIColor(white: 0.8, alpha: 1))
        
        let priceMASeries = CHSeries.getPriceMA(
            isEMA: false,
            num: [5,10,30],
            colors: [UIColor.ch_hex(0xDDDDDD),
                     UIColor.ch_hex(0xF9EE30),
                     UIColor.ch_hex(0xF600FF)],
            section: priceSection)
        priceMASeries.hidden = false
        
        let priceEMASeries = CHSeries.getPriceMA(
            isEMA: true,
            num: [5,10,30],
            colors: [UIColor.ch_hex(0xDDDDDD),
                     UIColor.ch_hex(0xF9EE30),
                     UIColor.ch_hex(0xF600FF)],
            section: priceSection)
        priceEMASeries.hidden = true
        
        let priceBOLLSeries = CHSeries.getBOLL(
            UIColor.ch_hex(0xDDDDDD),
            ubc: UIColor.ch_hex(0xF9EE30),
            lbc: UIColor.ch_hex(0xF600FF),
            section: priceSection)
        priceBOLLSeries.hidden = true
        
        let priceSARSeries = CHSeries.getSAR(
            upStyle: upcolor,
            downStyle: downcolor,
            titleColor: UIColor.ch_hex(0xDDDDDD),
            section: priceSection)
        priceSARSeries.hidden = true
        
        priceSection.series = [timelineSeries,
                               priceSeries,
                               priceMASeries,
                               priceEMASeries,
                               priceBOLLSeries,
                               priceSARSeries]
        
        let volumeSection = CHSection()
        volumeSection.backgroundColor = style.backgroundColor
        volumeSection.valueType = .assistant
        volumeSection.key = "volume"
        volumeSection.hidden = false
        volumeSection.ratios = 1
        volumeSection.yAxis.tickInterval = 4
        volumeSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        let volumeSeries = CHSeries.getDefaultVolume(upStyle: upcolor, downStyle: downcolor, section: volumeSection)
        
        let volumeMASeries = CHSeries.getVolumeMA(
            isEMA: false,
            num: [5,10,30],
            colors: [UIColor.ch_hex(0xDDDDDD),
                     UIColor.ch_hex(0xF9EE30),
                     UIColor.ch_hex(0xF600FF)],
            section: volumeSection)
        
        let volumeEMASeries = CHSeries.getVolumeMA(
            isEMA: true,
            num: [5,10,30],
            colors: [UIColor.ch_hex(0xDDDDDD),
                     UIColor.ch_hex(0xF9EE30),
                     UIColor.ch_hex(0xF600FF)],
            section: volumeSection)
        volumeEMASeries.hidden = true
        
        volumeSection.series = [volumeSeries, volumeMASeries, volumeEMASeries]
        
        let trendSection = CHSection()
        trendSection.backgroundColor = style.backgroundColor
        trendSection.valueType = .assistant
        trendSection.key = "analysis"
        trendSection.hidden = false
        trendSection.ratios = 1
        trendSection.paging = true
        trendSection.yAxis.tickInterval = 4
        trendSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        let kdjSeries = CHSeries.getKDJ(
            UIColor.ch_hex(0xDDDDDD),
            dc: UIColor.ch_hex(0xF9EE30),
            jc: UIColor.ch_hex(0xF600FF),
            section: trendSection)
        kdjSeries.title = "KDJ(9,3,3)"
        
        let macdSeries = CHSeries.getMACD(
            UIColor.ch_hex(0xDDDDDD),
            deac: UIColor.ch_hex(0xF9EE30),
            barc: UIColor.ch_hex(0xF600FF),
            upStyle: upcolor, downStyle: downcolor,
            section: trendSection)
        macdSeries.title = "MACD(12,26,9)"
        macdSeries.symmetrical = true
        
        trendSection.series = [kdjSeries, macdSeries]
        
        style.sections = [priceSection, volumeSection, trendSection]
        
        return style
    }
}
