
import UIKit

public struct BMKLineSeriesKey {
    public static let candle = "Candle"
    public static let timeline = "Timeline"
    public static let volume = "Volume"
    public static let ma = "MA"
    public static let ema = "EMA"
    public static let boll = "BOLL"
    public static let macd = "MACD"
    public static let kdj = "KDJ"
    public static let sar = "SAR"
    public static let rsi = "RSI"
}

/// 系列
/// 图表中一个要显示的线段都是以一个 Series 进行封装
/// 蜡烛图线段: 包含一个蜡烛图点线模型(CandleModel)
/// 时分线段: 包含一个线点线模型(LineModel)
/// 交易量线段: 包含一个交易量点线模型(ColumnModel)
/// MA/EMA 线段: 包含一个线点线模型(LineModel)
/// KDJ 线段: 包含3个线点线模型(LineModel), 3个点线的数值根据 KDJ 指标算法计算所得
/// MACD 线段: 包含2个线点线模型(LineModel), 1个条形点线模型(BarModel)
open class BMKLineSeries: NSObject {
    
    open var key = ""
    open var title: String = ""
    open var chartModels: [BMKLineChartModel] = [] // 每个系列可能包含多个点线模型
    open var hidden: Bool = false                // 是否隐藏
    open var showTitle: Bool = true              // 是否显示标题文本
    open var baseValueSticky = false             // 是否以固定基值显示最小或最大值, 若超过范围
    open var symmetrical = false                 // 是否以固定基值为中位数, 对称显示最大最小值
    
    public var algorithms: [BMKLineIndexAlgorithmProtocol] = []
    
    var seriesLayer: BMKLineShapeLayer = BMKLineShapeLayer()
    
    func removeSublayers() {
        self.seriesLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        self.seriesLayer.sublayers?.removeAll()
    }
}

// MARK: - 工厂方法
extension BMKLineSeries {
    
    /// 返回一个标准的分时价格系列样式
    ///
    /// - Parameters:
    ///   - color: 线段颜色
    ///   - section: 分区
    ///   - showGuide: 是否显示最大最小值
    ///   - ultimateValueStyle: 最大最小值显示风格
    ///   - lineWidth: 线宽
    /// - Returns: 线系列模型
    public class func getTimelinePrice(
        color: UIColor,
        section: BMKLineSection,
        showUltimateValue: Bool = false,
        ultimateValueStyle: BMUltimateValueStyle = .none,
        lineWidth: CGFloat = 1
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.timeline
        let line = BMKLineChartModel.getLine(
            color,
            title: NSLocalizedString("Price", comment: ""),
            key: "\(BMKLineSeriesKey.timeline)_\(BMKLineSeriesKey.timeline)"
        )
        line.section = section
        line.useTitleColor = false
        line.ultimateValueStyle = ultimateValueStyle
        line.showMaxVal = showUltimateValue
        line.showMinVal = showUltimateValue
        line.lineWidth = lineWidth
        series.chartModels = [line]
        return series
    }
    
    /// 返回一个标准的蜡烛柱价格系列样式
    public class func getCandlePrice(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        titleColor: UIColor,
        section: BMKLineSection,
        showUltimateValue: Bool = false,
        ultimateValueStyle: BMUltimateValueStyle = .none
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.candle
        let candle = BMKLineChartModel.getCandle(
            upStyle: upStyle,
            downStyle: downStyle,
            titleColor: titleColor
        )
        candle.section = section
        candle.useTitleColor = false
        candle.showMaxVal = showUltimateValue
        candle.showMinVal = showUltimateValue
        candle.ultimateValueStyle = ultimateValueStyle
        series.chartModels = [candle]
        return series
    }
    
    /// 返回一个标准的交易量系列样式
    public class func getDefaultVolume(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.volume
        let volume = BMKLineChartModel.getVolume(upStyle: upStyle, downStyle: downStyle)
        volume.section = section
        volume.useTitleColor = false
        series.chartModels = [volume]
        return series
    }
    
    /// 返回一个交易量的 MA 系列样式
    public class func getVolumeMA(
        isEMA: Bool = false,
        num: [Int],
        colors: [UIColor],
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let valueKey = BMKLineSeriesKey.volume
        let series = self.getMA(
            isEMA: isEMA,
            num: num,
            colors: colors,
            valueKey: valueKey,
            section: section
        )
        return series
    }
    
    /// 返回一个交易量和 MA 组合的系列样式
    public class func getVolumeWithMA(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        isEMA: Bool = false,
        num: [Int],
        colors: [UIColor],
        section: BMKLineSection) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.volume
        let volumeSeries = BMKLineSeries.getDefaultVolume(
            upStyle: upStyle,
            downStyle: downStyle,
            section: section
        )
        let volumeMASeries = BMKLineSeries.getVolumeMA(
            isEMA: isEMA,
            num: num,
            colors: colors,
            section: section
        )
        series.chartModels.append(contentsOf: volumeSeries.chartModels)
        series.chartModels.append(contentsOf: volumeMASeries.chartModels)
        return series
    }
    
    /// 返回一个价格的 MA 系列样式
    public class func getPriceMA(
        isEMA: Bool = false,
        num: [Int],
        colors: [UIColor],
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let valueKey = BMKLineSeriesKey.timeline
        let series = self.getMA(
            isEMA: isEMA,
            num: num,
            colors: colors,
            valueKey: valueKey,
            section: section
        )
        return series
    }
    
    /// 返回一个移动平均线系列样式
    public class func getMA(
        isEMA: Bool = false,
        num: [Int],
        colors: [UIColor],
        valueKey: String,
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        var key = ""
        if isEMA {
            key = BMKLineSeriesKey.ema
        } else {
            key = BMKLineSeriesKey.ma
        }
        let series = BMKLineSeries()
        series.key = key
        for (i, n) in num.enumerated() {
            let ma = BMKLineChartModel.getLine(colors[i], title: "\(key)\(n)", key: "\(key)_\(n)_\(valueKey)")
            ma.section = section
            series.chartModels.append(ma)
        }
        return series
    }
    
    /// 返回一个 BOLL 系列样式
    public class func getBOLL(
        _ bollc: UIColor,
        ubc: UIColor,
        lbc: UIColor,
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.boll
        let boll = BMKLineChartModel.getLine(bollc, title: "BOLL", key: "\(BMKLineSeriesKey.boll)_BOLL")
        boll.section = section
        let ub = BMKLineChartModel.getLine(ubc, title: "UB", key: "\(BMKLineSeriesKey.boll)_UB")
        ub.section = section
        let lb = BMKLineChartModel.getLine(lbc, title: "LB", key: "\(BMKLineSeriesKey.boll)_LB")
        lb.section = section
        series.chartModels = [boll, ub, lb]
        return series
    }
    
    /// 返回一个 MACD 系列样式
    public class func getMACD(
        _ difc: UIColor,
        deac: UIColor,
        barc: UIColor,
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.macd
        let dif = BMKLineChartModel.getLine(difc, title: "DIF", key: "\(BMKLineSeriesKey.macd)_DIF")
        dif.section = section
        let dea = BMKLineChartModel.getLine(deac, title: "DEA", key: "\(BMKLineSeriesKey.macd)_DEA")
        dea.section = section
        let bar = BMKLineChartModel.getBar(
            upStyle: upStyle,
            downStyle: downStyle,
            titleColor: barc,
            title: "MACD",
            key: "\(BMKLineSeriesKey.macd)_BAR"
        )
        bar.section = section
        series.chartModels = [bar, dif, dea]
        return series
    }
    
    /// 返回一个 KDJ 系列样式
    public class func getKDJ(
        _ kc: UIColor,
        dc: UIColor,
        jc: UIColor,
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.kdj
        let k = BMKLineChartModel.getLine(kc, title: "K", key: "\(BMKLineSeriesKey.kdj)_K")
        k.section = section
        let d = BMKLineChartModel.getLine(dc, title: "D", key: "\(BMKLineSeriesKey.kdj)_D")
        d.section = section
        let j = BMKLineChartModel.getLine(jc, title: "J", key: "\(BMKLineSeriesKey.kdj)_J")
        j.section = section
        series.chartModels = [k, d, j]
        return series
    }
    
    /// 返回一个 RSI 系列样式
    public class func getRSI(
        num: [Int],
        colors: [UIColor],
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.rsi
        for (i, n) in num.enumerated() {
            let ma = BMKLineChartModel.getLine(
                colors[i],
                title: "\(series.key)\(n)",
                key: "\(series.key)_\(n)_\(BMKLineSeriesKey.timeline)"
            )
            ma.section = section
            series.chartModels.append(ma)
        }
        return series
    }
    
    /// 返回一个 SAR 系列样式
    public class func getSAR(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        titleColor: UIColor,
        plotPaddingExt: CGFloat = 0.3,
        section: BMKLineSection
        ) -> BMKLineSeries
    {
        let series = BMKLineSeries()
        series.key = BMKLineSeriesKey.sar
        let sar = BMKLineChartModel.getRound(
            upStyle: upStyle,
            downStyle: downStyle,
            titleColor: titleColor,
            title: "SAR",
            plotPaddingExt: plotPaddingExt,
            key: "\(BMKLineSeriesKey.sar)"
        )
        sar.section = section
        sar.useTitleColor = true
        series.chartModels = [sar]
        return series
    }
    
}
