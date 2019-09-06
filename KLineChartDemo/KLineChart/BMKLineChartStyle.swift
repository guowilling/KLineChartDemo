
import Foundation
import UIKit

/// 最大最小值显示风格
///
/// - none: 不显示
/// - arrow: 箭头
/// - circle: 空心圆
/// - tag: 标签
public enum BMUltimateValueStyle {
    case none
    case arrow(UIColor)
    case circle(UIColor, Bool)
    case tag(UIColor)
}

// MARK: - 图表样式类
open class BMKLineChartStyle {
    
    /// 分区样式
    open var sections: [BMKLineSection] = []
    
    /// 支持的指标算法
    open var algorithms: [BMKLineIndexAlgorithmProtocol] = []
    
    /// 背景颜色
    open var backgroundColor: UIColor = UIColor.white
    
    /// 边线宽度上左下右
    open var borderWidth: (top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) = (0.5, 0.5, 0.5, 0.5)
    
    /// 边距
    open var padding: UIEdgeInsets!
    
    /// 字体大小
    open var labelFont: UIFont!
    
    /// 边框线条颜色
    open var lineColor: UIColor = UIColor.clear
    
    /// XY 轴上 Label 颜色
    open var textColor: UIColor = UIColor.clear
    
    /// 是否显示选中点
    open var showSelection: Bool = true
    
    /// 选中点的背景颜色
    open var selectedBGColor: UIColor = UIColor.clear
    
    /// 选中点时显示的 XY 轴上 Label 颜色
    open var selectedTextColor: UIColor = UIColor.clear
    
    /// Y 轴的位置, 默认右边
    open var yAxisShowPosition = BMKLineYAxisShowPosition.right
    
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
    open var isShowPlotAll: Bool = false
    
    public init() {}
}

public extension BMKLineChartStyle {
    
    /// 基本图表样式
    static var base: BMKLineChartStyle {
        let style = BMKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor(white: 0.2, alpha: 1)
        style.textColor = UIColor(white: 0.8, alpha: 1)
        style.selectedBGColor = UIColor(white: 0.4, alpha: 1)
        style.selectedTextColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        style.padding = UIEdgeInsets(top: 32, left: 8, bottom: 4, right: 0)
        style.backgroundColor = UIColor.bm_hex(0x1D1C1C)
        style.yAxisShowPosition = .right
        
        style.algorithms = [
            BMKLineIndexAlgorithm.timeline,
            BMKLineIndexAlgorithm.sar(4, 0.02, 0.2), // 默认周期4, 最小加速0.02, 最大加速0.2
            BMKLineIndexAlgorithm.ma(5),
            BMKLineIndexAlgorithm.ma(10),
            BMKLineIndexAlgorithm.ma(20),            // 计算 BOLL, 必须先计算同周期的 MA
            BMKLineIndexAlgorithm.ma(30),
            BMKLineIndexAlgorithm.ema(5),
            BMKLineIndexAlgorithm.ema(10),
            BMKLineIndexAlgorithm.ema(12),           // 计算 MACD, 必须先计算同周期的 EMA
            BMKLineIndexAlgorithm.ema(26),           // 计算 MACD, 必须先计算同周期的 EMA
            BMKLineIndexAlgorithm.ema(30),
            BMKLineIndexAlgorithm.boll(20, 2),
            BMKLineIndexAlgorithm.macd(12, 26, 9),
            BMKLineIndexAlgorithm.kdj(9, 3, 3),
        ]
        
        let upcolor = (UIColor.bm_hex(0xF80D1F), true)
        let downcolor = (UIColor.bm_hex(0x1E932B), true)
        let priceSection = BMKLineSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.isShowTitleOutside = true
        priceSection.type = .master
        priceSection.key = "master"
        priceSection.isHidden = false
        priceSection.ratios = 3
        priceSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        
        /// 时分线
        let timelineSeries = BMKLineSeries.getTimelinePrice(
            color: UIColor.bm_hex(0xAE475C),
            section: priceSection,
            showUltimateValue: true,
            ultimateValueStyle: .circle(UIColor.bm_hex(0xAE475C), true),
            lineWidth: 2
        )
        timelineSeries.hidden = true
        
        /// 蜡烛线
        let priceSeries = BMKLineSeries.getCandlePrice(
            upStyle: upcolor,
            downStyle: downcolor,
            titleColor: UIColor(white: 0.8, alpha: 1),
            section: priceSection,
            showUltimateValue: true,
            ultimateValueStyle: .arrow(UIColor(white: 0.8, alpha: 1))
        )
        priceSeries.showTitle = true
        priceSeries.chartModels.first?.ultimateValueStyle = .arrow(UIColor(white: 0.8, alpha: 1))
        
        let priceMASeries = BMKLineSeries.getPriceMA(
            isEMA: false,
            num: [5,10,30],
            colors: [
                UIColor.bm_hex(0xDDDDDD),
                UIColor.bm_hex(0xF9EE30),
                UIColor.bm_hex(0xF600FF),
            ],
            section: priceSection
        )
        priceMASeries.hidden = false
        
        let priceEMASeries = BMKLineSeries.getPriceMA(
            isEMA: true,
            num: [5,10,30],
            colors: [
                UIColor.bm_hex(0xDDDDDD),
                UIColor.bm_hex(0xF9EE30),
                UIColor.bm_hex(0xF600FF),
            ],
            section: priceSection
        )
        priceEMASeries.hidden = true
        
        let priceBOLLSeries = BMKLineSeries.getBOLL(
            UIColor.bm_hex(0xDDDDDD),
            ubc: UIColor.bm_hex(0xF9EE30),
            lbc: UIColor.bm_hex(0xF600FF),
            section: priceSection
        )
        priceBOLLSeries.hidden = true
        
        let priceSARSeries = BMKLineSeries.getSAR(
            upStyle: upcolor,
            downStyle: downcolor,
            titleColor: UIColor.bm_hex(0xDDDDDD),
            section: priceSection
        )
        priceSARSeries.hidden = true
        
        priceSection.seriesArray = [
            timelineSeries,
            priceSeries,
            priceMASeries,
            priceEMASeries,
            priceBOLLSeries,
            priceSARSeries,
        ]
        
        let volumeSection = BMKLineSection()
        volumeSection.backgroundColor = style.backgroundColor
        volumeSection.type = .assistant
        volumeSection.key = "volume"
        volumeSection.isHidden = false
        volumeSection.ratios = 1
        volumeSection.yAxis.tickInterval = 4
        volumeSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        let volumeSeries = BMKLineSeries.getDefaultVolume(upStyle: upcolor, downStyle: downcolor, section: volumeSection)
        
        let volumeMASeries = BMKLineSeries.getVolumeMA(
            isEMA: false,
            num: [5,10,30],
            colors: [
                UIColor.bm_hex(0xDDDDDD),
                UIColor.bm_hex(0xF9EE30),
                UIColor.bm_hex(0xF600FF),
            ],
            section: volumeSection
        )
        
        let volumeEMASeries = BMKLineSeries.getVolumeMA(
            isEMA: true,
            num: [5,10,30],
            colors: [
                UIColor.bm_hex(0xDDDDDD),
                UIColor.bm_hex(0xF9EE30),
                UIColor.bm_hex(0xF600FF),
            ],
            section: volumeSection)
        volumeEMASeries.hidden = true
        
        volumeSection.seriesArray = [volumeSeries, volumeMASeries, volumeEMASeries]
        
        let trendSection = BMKLineSection()
        trendSection.backgroundColor = style.backgroundColor
        trendSection.type = .assistant
        trendSection.key = "analysis"
        trendSection.isHidden = false
        trendSection.ratios = 1
        trendSection.isPageable = true
        trendSection.yAxis.tickInterval = 4
        trendSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        let kdjSeries = BMKLineSeries.getKDJ(
            UIColor.bm_hex(0xDDDDDD),
            dc: UIColor.bm_hex(0xF9EE30),
            jc: UIColor.bm_hex(0xF600FF),
            section: trendSection
        )
        kdjSeries.title = "KDJ(9,3,3)"
        
        let macdSeries = BMKLineSeries.getMACD(
            UIColor.bm_hex(0xDDDDDD),
            deac: UIColor.bm_hex(0xF9EE30),
            barc: UIColor.bm_hex(0xF600FF),
            upStyle: upcolor,
            downStyle: downcolor,
            section: trendSection
        )
        macdSeries.title = "MACD(12,26,9)"
        macdSeries.symmetrical = true
        
        trendSection.seriesArray = [kdjSeries, macdSeries]
        
        style.sections = [priceSection, volumeSection, trendSection]
        
        return style
    }
}
