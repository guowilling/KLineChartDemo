
import UIKit
//import CHKLineChartKit

class KLineChartStyleManager: NSObject, Codable {
    
    /// 主题风格名称: Dark/Light
    var theme: String = ""
    
    var showYAxisLabel = "right"
    
    var candleColors = "Green/Red"
    
    var backgroundColor: UInt = 0x232732
    
    var textColor: UInt = 0xcccccc

    var selectedTextColor: UInt = 0xcccccc
    
    var lineColor: UInt = 0x333333
    
    var upColor: UInt = 0x00bd9a

    var downColor: UInt = 0xff6960

    var lineColors: [UInt] = [0xDDDDDD, 0xF9EE30, 0xF600FF]
    
    var isInnerYAxis: Bool = false
    
    static var shared: KLineChartStyleManager = {
        let instance = KLineChartStyleManager.loadUserData()
        return instance
    }()
    
    static var defaultStyle: KLineChartStyleManager {
        let style = KLineChartStyleManager()
        style.theme = "Dark"
        style.candleColors = "Green/Red"
        style.showYAxisLabel = "right"
        style.isInnerYAxis = false
        style.backgroundColor = 0x232732
        style.textColor = 0xcccccc
        style.selectedTextColor = 0xcccccc
        style.lineColor = 0x333333
        style.upColor = 0x00bd9a
        style.downColor = 0xff6960
        style.lineColors = [0xDDDDDD, 0xF9EE30, 0xF600FF]
        style.isInnerYAxis = false        
        return style
    }
    
    static func loadUserData() -> KLineChartStyleManager {
        guard let json = UserDefaults.standard.value(forKey: "CustomKLineChartStyle") as? String else {
            return KLineChartStyleManager.defaultStyle
        }
        guard let jsonData = json.data(using: String.Encoding.utf8) else {
            return KLineChartStyleManager.defaultStyle
        }
        let jsonDecoder = JSONDecoder()
        do {
            let csm = try jsonDecoder.decode(KLineChartStyleManager.self, from: jsonData)
            return csm
        } catch _ {
            return KLineChartStyleManager.defaultStyle
        }
    }
    
    func saveUserData() -> Bool {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(self)
            let jsonString = String(data: jsonData, encoding: .utf8)
            UserDefaults.standard.set(jsonString, forKey: "CustomKLineChartStyle")
            UserDefaults.standard.synchronize()
            return true
        } catch _ {
            return false
        }
    }
    
    static func resetDefault() {
        KLineChartStyleManager.shared = KLineChartStyleManager.defaultStyle
        _ = KLineChartStyleManager.shared.saveUserData()
    }
}

// MARK: - 扩展样式
public extension CHKLineChartStyle {
    
    /// 自定义的明亮风格样式
    public static var customLight: CHKLineChartStyle {
        let style = CHKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor.clear
        style.selectedBGColor = UIColor(white: 0.4, alpha: 1)
        style.textColor = UIColor(white: 0.5, alpha: 1)
        style.backgroundColor = UIColor.white
        style.selectedTextColor = UIColor(white: 0.8, alpha: 1)
        style.padding = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        style.isInnerYAxis = true
        style.showXAxisOnSection = 0
        style.yAxisShowPosition = .right
        style.algorithms = [CHChartAlgorithm.timeline,
                            CHChartAlgorithm.ma(5),
                            CHChartAlgorithm.ma(10),
                            CHChartAlgorithm.ma(30),
                            CHChartAlgorithm.ema(5),
                            CHChartAlgorithm.ema(10),
                            CHChartAlgorithm.ema(12),
                            CHChartAlgorithm.ema(26),
                            CHChartAlgorithm.ema(30),
                            CHChartAlgorithm.macd(12, 26, 9), // 计算 MACD, 必须先计算到同周期的 EMA
                            CHChartAlgorithm.kdj(9, 3, 3),
                            CHChartAlgorithm.rsi(6),
                            CHChartAlgorithm.rsi(12),
                            CHChartAlgorithm.rsi(24)]
        
        let upcolor = (UIColor.ch_hex(0x5BA267), true)
        let downcolor = (UIColor.ch_hex(0xB1414C), true)
        let priceSection = CHSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.titleShowOutSide = false
        priceSection.showTitle = false
        priceSection.valueType = .master
        priceSection.key = "price"
        priceSection.hidden = false
        priceSection.ratios = 0
        priceSection.fixHeight = 176
        priceSection.yAxis.referenceStyle = .none
        priceSection.padding = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        /// 时分线
        let timelineSeries = CHSeries.getTimelinePrice(color: UIColor.ch_hex(0xAE475C),
                                                       section: priceSection,
                                                       showGuide: true,
                                                       ultimateValueStyle: .circle(UIColor.ch_hex(0xAE475C), true),
                                                       lineWidth: 2)
        timelineSeries.hidden = true
        
        /// 蜡烛线
        let priceSeries = CHSeries.getCandlePrice(upStyle: upcolor,
                                                  downStyle: downcolor,
                                                  titleColor: UIColor(white: 0.5, alpha: 1),
                                                  section: priceSection,
                                                  showGuide: true,
                                                  ultimateValueStyle: .arrow(UIColor(white: 0.5, alpha: 1)))
        
        let maColor = [UIColor.ch_hex(0x4E9CC1),
                       UIColor.ch_hex(0xF7A23B),
                       UIColor.ch_hex(0xF600FF)]
        
        /// MA
        let priceMASeries = CHSeries.getPriceMA(isEMA: false,
                                                num: [5,10,30],
                                                colors:maColor,
                                                section: priceSection)
        priceMASeries.hidden = false
        
        // EMA
        let priceEMASeries = CHSeries.getPriceMA(isEMA: true,
                                                 num: [5,10,30],
                                                 colors: maColor,
                                                 section: priceSection)
        priceEMASeries.hidden = true
        priceSection.series = [timelineSeries, priceSeries, priceMASeries, priceEMASeries]
        
        let volumeSection = CHSection()
        volumeSection.backgroundColor = style.backgroundColor
        volumeSection.valueType = .assistant
        volumeSection.key = "volume"
        volumeSection.hidden = false
        volumeSection.showTitle = false
        volumeSection.ratios = 1
        volumeSection.yAxis.referenceStyle = .none
        volumeSection.yAxis.tickInterval = 2
        volumeSection.padding = UIEdgeInsets(top: 10, left: 0, bottom: 4, right: 0)
        let volumeSeries = CHSeries.getDefaultVolume(upStyle: upcolor,
                                                     downStyle: downcolor,
                                                     section: volumeSection)
        let volumeMASeries = CHSeries.getVolumeMA(isEMA: false,
                                                  num: [5,10,30],
                                                  colors: maColor,
                                                  section: volumeSection)
        let volumeEMASeries = CHSeries.getVolumeMA(isEMA: true,
                                                   num: [5,10,30],
                                                   colors: maColor,
                                                   section: volumeSection)
        volumeEMASeries.hidden = true
        volumeSection.series = [volumeSeries, volumeMASeries, volumeEMASeries]
        
        let trendSection = CHSection()
        trendSection.backgroundColor = style.backgroundColor
        trendSection.valueType = .assistant
        trendSection.key = "analysis"
        trendSection.hidden = false
        trendSection.showTitle = false
        trendSection.ratios = 1
        trendSection.paging = true
        trendSection.yAxis.referenceStyle = .none
        trendSection.yAxis.tickInterval = 2
        trendSection.padding = UIEdgeInsets(top: 10, left: 0, bottom: 8, right: 0)
        let kdjSeries = CHSeries.getKDJ(UIColor.ch_hex(0xDDDDDD),
                                        dc: UIColor.ch_hex(0xF9EE30),
                                        jc: UIColor.ch_hex(0xF600FF),
                                        section: trendSection)
        kdjSeries.title = "KDJ(9,3,3)"
        
        let macdSeries = CHSeries.getMACD(UIColor.ch_hex(0xDDDDDD),
                                          deac: UIColor.ch_hex(0xF9EE30),
                                          barc: UIColor.ch_hex(0xF600FF),
                                          upStyle: upcolor, downStyle: downcolor,
                                          section: trendSection)
        macdSeries.title = "MACD(12,26,9)"
        macdSeries.symmetrical = true
        trendSection.series = [macdSeries, kdjSeries]
        
        style.sections = [priceSection, volumeSection, trendSection]
        
        return style
    }
    
    /// 自定义暗黑风格的样式
    public static var customDark: CHKLineChartStyle {
        let style = CHKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor.clear
        style.selectedBGColor = UIColor(white: 0.4, alpha: 1)
        style.textColor = UIColor(white: 0.8, alpha: 1)
        style.backgroundColor = UIColor.ch_hex(0x1D1C1C)
        style.selectedTextColor = UIColor(white: 0.8, alpha: 1)
        style.padding = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        style.isInnerYAxis = true
        style.showXAxisOnSection = 0
        style.yAxisShowPosition = .right
        style.algorithms = [CHChartAlgorithm.timeline,
                            CHChartAlgorithm.ma(5),
                            CHChartAlgorithm.ma(10),
                            CHChartAlgorithm.ma(30),
                            CHChartAlgorithm.ema(5),
                            CHChartAlgorithm.ema(10),
                            CHChartAlgorithm.ema(12),
                            CHChartAlgorithm.ema(26),
                            CHChartAlgorithm.ema(30),
                            CHChartAlgorithm.macd(12, 26, 9),
                            CHChartAlgorithm.kdj(9, 3, 3)]
        
        let upcolor = (UIColor.ch_hex(0x5BA267), true)
        let downcolor = (UIColor.ch_hex(0xB1414C), true)
        let priceSection = CHSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.titleShowOutSide = false
        priceSection.showTitle = false
        priceSection.valueType = .master
        priceSection.key = "price"
        priceSection.hidden = false
        priceSection.ratios = 0
        priceSection.fixHeight = 176
        priceSection.yAxis.referenceStyle = .none
        priceSection.yAxis.tickInterval = 3
        priceSection.padding = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        
        /// 时分线
        let timelineSeries = CHSeries.getTimelinePrice(color: UIColor.ch_hex(0xAE475C),
                                                       section: priceSection,
                                                       showGuide: true,
                                                       ultimateValueStyle: .circle(UIColor.ch_hex(0xAE475C), true),
                                                       lineWidth: 2)
        timelineSeries.hidden = true
        
        /// 蜡烛线
        let priceSeries = CHSeries.getCandlePrice(
            upStyle: upcolor,
            downStyle: downcolor,
            titleColor: UIColor(white: 0.5, alpha: 1),
            section: priceSection,
            showGuide: true,
            ultimateValueStyle: .tag(UIColor.white))
        
        let maColor = [UIColor.ch_hex(0xDDDDDD),
                       UIColor.ch_hex(0xF9EE30),
                       UIColor.ch_hex(0xF600FF)]
        
        // MA
        let priceMASeries = CHSeries.getPriceMA(isEMA: false,
            num: [5,10,30],
            colors:maColor,
            section: priceSection)
        priceMASeries.hidden = false
        
        // EMA
        let priceEMASeries = CHSeries.getPriceMA(
            isEMA: true,
            num: [5,10,30],
            colors: maColor,
            section: priceSection)
        priceEMASeries.hidden = true
        priceSection.series = [timelineSeries, priceSeries, priceMASeries, priceEMASeries]
        
        let volumeSection = CHSection()
        volumeSection.backgroundColor = style.backgroundColor
        volumeSection.valueType = .assistant
        volumeSection.key = "volume"
        volumeSection.hidden = false
        volumeSection.showTitle = false
        volumeSection.ratios = 1
        volumeSection.yAxis.referenceStyle = .none
        volumeSection.yAxis.tickInterval = 1
        volumeSection.padding = UIEdgeInsets(top: 10, left: 0, bottom: 4, right: 0)
        let volumeSeries = CHSeries.getDefaultVolume(
            upStyle: upcolor,
            downStyle: downcolor,
            section: volumeSection)
        
        let volumeMASeries = CHSeries.getVolumeMA(
            isEMA: false,
            num: [5,10,30],
            colors: maColor,
            section: volumeSection)
        
        let volumeEMASeries = CHSeries.getVolumeMA(
            isEMA: true,
            num: [5,10,30],
            colors: maColor,
            section: volumeSection)
        volumeEMASeries.hidden = true
        volumeSection.series = [volumeSeries, volumeMASeries, volumeEMASeries]
        
        let trendSection = CHSection()
        trendSection.backgroundColor = style.backgroundColor
        trendSection.valueType = .assistant
        trendSection.key = "analysis"
        trendSection.hidden = false
        trendSection.showTitle = false
        trendSection.ratios = 1
        trendSection.paging = true
        trendSection.yAxis.referenceStyle = .none
        trendSection.yAxis.tickInterval = 2
        trendSection.padding = UIEdgeInsets(top: 10, left: 0, bottom: 8, right: 0)
        let kdjSeries = CHSeries.getKDJ(UIColor.ch_hex(0xDDDDDD),
                                        dc: UIColor.ch_hex(0xF9EE30),
                                        jc: UIColor.ch_hex(0xF600FF),
                                        section: trendSection)
        kdjSeries.title = "KDJ(9,3,3)"
        
        let macdSeries = CHSeries.getMACD(UIColor.ch_hex(0xDDDDDD),
                                          deac: UIColor.ch_hex(0xF9EE30),
                                          barc: UIColor.ch_hex(0xF600FF),
                                          upStyle: (UIColor.ch_hex(0x5BA267), false), downStyle: downcolor,
                                          section: trendSection)
        macdSeries.title = "MACD(12,26,9)"
        macdSeries.symmetrical = true
        trendSection.series = [macdSeries, kdjSeries]
        
        style.sections = [priceSection, volumeSection, trendSection]
        
        return style
    }
    
    /// 暗黑风格的点线简单样式
    public static var simpleLineDark: CHKLineChartStyle {
        let style = CHKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor.clear
        style.textColor = UIColor.ch_hex(0x8D7B62, alpha: 0.44)
        style.selectedTextColor = UIColor(white: 0.8, alpha: 1)
        style.backgroundColor = UIColor.ch_hex(0x383D49)
        style.selectedBGColor = UIColor(white: 0.4, alpha: 1)
        style.padding = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        style.yAxisShowPosition = .left
        style.showXAxisOnSection = 0
        style.isInnerYAxis = true
        style.isShowAll = true
        style.enablePan = false
        style.enableTap = false
        style.enablePinch = false
        style.algorithms = [CHChartAlgorithm.timeline]
        
        let priceSection = CHSection()
        priceSection.valueType = .master
        priceSection.key = "price"
        priceSection.backgroundColor = style.backgroundColor
        priceSection.titleShowOutSide = false
        priceSection.showTitle = false
        priceSection.hidden = false
        priceSection.ratios = 1
        priceSection.yAxis.tickInterval = 2
        priceSection.yAxis.referenceStyle = .solid(color: UIColor.ch_hex(0x8D7B62, alpha: 0.44))
        priceSection.padding = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        let timelineSeries = CHSeries.getTimelinePrice(color: UIColor.ch_hex(0xAE475C),
                                                       section: priceSection,
                                                       showGuide: true,
                                                       ultimateValueStyle: .circle(UIColor.ch_hex(0xAE475C), true),
                                                       lineWidth: 2)
        priceSection.series = [timelineSeries]
        
        style.sections = [priceSection]
        
        return style
    }
}
