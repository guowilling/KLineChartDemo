
import UIKit

/// 走势方向
///
/// - up: 涨
/// - down: 跌
/// - equal: 平
public enum BMKLineChartItemTrend {
    case up
    case down
    case equal
}

/// 图表数据元素
open class BMKLineChartItem: NSObject {
    
    open var time: Int = 0
    open var openPrice: CGFloat = 0  // 开盘价
    open var closePrice: CGFloat = 0 // 收盘价
    open var lowPrice: CGFloat = 0   // 最低价
    open var highPrice: CGFloat = 0  // 最高价
    open var vol: CGFloat = 0        // 交易量
    open var value: CGFloat?
    
    /// 扩展值用于记录各种技术指标
    open var extVal: [String: CGFloat] = [:]
    
    open var trend: BMKLineChartItemTrend {
        if closePrice == openPrice {
            return .equal
        }
        if closePrice < openPrice {
            return .down
        } else {
            return .up
        }
    }
}

/// 图表数据模型
open class BMKLineChartModel {
    
    open var datas: [BMKLineChartItem] = []
    open var upStyle: (color: UIColor, isSolid: Bool) = (.green, true)
    open var downStyle: (color: UIColor, isSolid: Bool) = (.red, true)
    open var title: String = ""                               // 标题
    open var titleColor = UIColor.white                       // 标题颜色
    open var decimal: Int = 2                                 // 保留几位小数
    open var showMaxVal: Bool = false                         // 是否显示最大值
    open var showMinVal: Bool = false                         // 是否显示最小值
    open var useTitleColor = true
    open var key: String = ""
    open var ultimateValueStyle: BMUltimateValueStyle = .none // 最大最小值显示样式
    open var lineWidth: CGFloat = 0.6                         // 线段宽度
    open var plotPaddingExt: CGFloat =  0.165                 // 点与点之间, 间断所占点宽的比例
    weak var section: BMKLineSection!
    
    convenience init(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        title: String = "",
        titleColor: UIColor,
        datas: [BMKLineChartItem] = [BMKLineChartItem](),
        decimal: Int = 2,
        plotPaddingExt: CGFloat = 0.165
        )
    {
        self.init()
        self.upStyle = upStyle
        self.downStyle = downStyle
        self.title = title
        self.titleColor = titleColor
        self.datas = datas
        self.decimal = decimal
        self.plotPaddingExt = plotPaddingExt
    }
    
    open func drawSerie(seriesKey: String? = nil, _ startIndex: Int, endIndex: Int) -> CAShapeLayer {
        return CAShapeLayer()
    }
}

open class BMLineModel: BMKLineChartModel {
    // MARK: - 点线样式模型
    open override func drawSerie(seriesKey: String? = nil, _ startIndex: Int, endIndex: Int) -> CAShapeLayer {
        let serieLayer = CAShapeLayer()
        
        let modelLayer = CAShapeLayer()
        modelLayer.strokeColor = self.upStyle.color.cgColor
        modelLayer.fillColor = UIColor.clear.cgColor
        modelLayer.lineWidth = self.lineWidth
        modelLayer.lineCap = .butt
        modelLayer.lineJoin = .round
        
        let linePath = UIBezierPath()
        
        // 每个点的间隔宽度
        let plotWidth = (self.section.frame.size.width - self.section.padding.left - self.section.padding.right) / CGFloat(endIndex - startIndex)
        
        var maxValue: CGFloat = 0                               // 最大值
        var maxPoint: CGPoint?                                  // 最大值所在坐标
        var minValue: CGFloat = CGFloat.greatestFiniteMagnitude // 最小值
        var minPoint: CGPoint?                                  // 最小值所在坐标
        
        var dataPoints: [CGPoint] = []
        // 循环起始到终结
        for i in stride(from: startIndex, to: endIndex, by: 1) {
            guard let value = self[i].value else {
                continue // 无法计算的值不绘画
            }
            let ix = self.section.frame.origin.x + self.section.padding.left + CGFloat(i - startIndex) * plotWidth
            let iys = self.section.getY(with: value)
            let point = CGPoint(x: ix + plotWidth / 2, y: iys)
            dataPoints.append(point)
            
            // 记录最大值
            if value > maxValue {
                maxValue = value
                maxPoint = point
            }
            // 记录最小值
            if value < minValue {
                minValue = value
                minPoint = point
            }
        }
        linePath.move(to: dataPoints[0])
        for i in 1..<dataPoints.count {
            linePath.addLine(to: dataPoints[i])
        }
        
        modelLayer.path = linePath.cgPath
        serieLayer.addSublayer(modelLayer)
        
        // 显示最大值
        if self.showMaxVal && maxValue != 0 {
            let highPrice = maxValue.bm_toString(maxF: section.decimal)
            let maxLayer = self.drawGuideValue(value: highPrice, section: section, point: maxPoint!, trend: BMKLineChartItemTrend.up)
            serieLayer.addSublayer(maxLayer)
        }
        // 显示最小值
        if self.showMinVal && minValue != CGFloat.greatestFiniteMagnitude {
            let lowPrice = minValue.bm_toString(maxF: section.decimal)
            let minLayer = self.drawGuideValue(value: lowPrice, section: section, point: minPoint!, trend: BMKLineChartItemTrend.down)
            serieLayer.addSublayer(minLayer)
        }
        
        return serieLayer
    }
}

open class BMCandleModel: BMKLineChartModel {
    // MARK: - 蜡烛样式模型
    var drawShadow = true
    
    open override func drawSerie(seriesKey: String? = nil, _ startIndex: Int, endIndex: Int) -> CAShapeLayer {
        let serieLayer = CAShapeLayer()
        
        let modelLayer = CAShapeLayer()
        // 每个点的间隔宽度
        let plotWidth = (self.section.frame.size.width - self.section.padding.left - self.section.padding.right) / CGFloat(endIndex - startIndex)
        var plotPadding = plotWidth * self.plotPaddingExt
        plotPadding = plotPadding < 0.25 ? 0.25 : plotPadding
        
        var maxValue: CGFloat = 0                               // 最大值
        var maxPoint: CGPoint?                                  // 最大值所在坐标
        var minValue: CGFloat = CGFloat.greatestFiniteMagnitude // 最小值
        var minPoint: CGPoint?                                  // 最小值所在坐标
        
        // 循环起始到终结
        for i in stride(from: startIndex, to: endIndex, by: 1) {
            if self.key != BMKLineSeriesKey.candle { // 如果不是蜡烛柱类型, 要读取具体的数值再绘制
                if self[i].value == nil {
                    continue // 无法计算的值不绘画
                }
            }
            var isSolid = true
            
            let candleLayer = CAShapeLayer()
            var candlePath: UIBezierPath?
            
            let shadowLayer = CAShapeLayer()
            let shadowPath = UIBezierPath()
            shadowPath.lineWidth = 0
            
            // 开始 x
            let ix = self.section.frame.origin.x + self.section.padding.left + CGFloat(i - startIndex) * plotWidth
            // 结束 x
            let iNx = self.section.frame.origin.x + self.section.padding.left + CGFloat(i + 1 - startIndex) * plotWidth
            
            let item = datas[i]
            // 具体的数值转为坐标系y轴值
            let iyo = self.section.getY(with: item.openPrice)
            let iyc = self.section.getY(with: item.closePrice)
            let iyh = self.section.getY(with: item.highPrice)
            let iyl = self.section.getY(with: item.lowPrice)
            
            switch item.trend {
            case .equal:
                // 开盘价 = 收盘价, 显示横线
                shadowLayer.strokeColor = self.upStyle.color.cgColor
                isSolid = true
            case .up:
                // 收盘价 > 开盘价, 显示涨的颜色
                shadowLayer.strokeColor = self.upStyle.color.cgColor
                candleLayer.strokeColor = self.upStyle.color.cgColor
                candleLayer.fillColor = self.upStyle.color.cgColor
                isSolid = self.upStyle.isSolid
            case .down:
                // 收盘价 < 开盘价, 显示跌的颜色
                shadowLayer.strokeColor = self.downStyle.color.cgColor
                candleLayer.strokeColor = self.downStyle.color.cgColor
                candleLayer.fillColor = self.downStyle.color.cgColor
                isSolid = self.downStyle.isSolid
            }
            
            // 1.先画最高和最低价格的线
            if self.drawShadow {
                shadowPath.move(to: CGPoint(x: ix + plotWidth / 2, y: iyh))
                shadowPath.addLine(to: CGPoint(x: ix + plotWidth / 2, y: iyl))
            }
            
            // 2.再画蜡烛柱的矩形
            switch item.trend {
            case .equal:
                // 显示横线
                shadowPath.move(to: CGPoint(x: ix + plotPadding, y: iyo))
                shadowPath.addLine(to: CGPoint(x: iNx - plotPadding, y: iyo))
            case .up:
                // 从收盘的Y值向下画矩形
                candlePath = UIBezierPath(rect: CGRect(x: ix + plotPadding, y: iyc, width: plotWidth - 2 * plotPadding, height: iyo - iyc))
            case .down:
                // 从开盘的Y值向下画矩形
                candlePath = UIBezierPath(rect: CGRect(x: ix + plotPadding, y: iyo, width: plotWidth - 2 *  plotPadding, height: iyc - iyo))
            }
            
            shadowLayer.path = shadowPath.cgPath
            modelLayer.addSublayer(shadowLayer)
            
            if candlePath != nil {
                // 如果自定义为空心, 需要把矩形缩小 lineWidth 一圈
                if isSolid {
                    candleLayer.lineWidth = self.lineWidth
                } else {
                    candleLayer.fillColor = UIColor.clear.cgColor
                    candleLayer.lineWidth = self.lineWidth
                }
                candleLayer.path = candlePath!.cgPath
                modelLayer.addSublayer(candleLayer)
            }
            
            // 记录最大值
            if item.highPrice > maxValue {
                maxValue = item.highPrice
                maxPoint = CGPoint(x: ix + plotWidth / 2, y: iyh)
            }
            // 记录最小值
            if item.lowPrice < minValue {
                minValue = item.lowPrice
                minPoint = CGPoint(x: ix + plotWidth / 2, y: iyl)
            }
        }
        
        serieLayer.addSublayer(modelLayer)
        
        // 显示最大值
        if self.showMaxVal && maxValue != 0 {
            let highPrice = maxValue.bm_toString(maxF: section.decimal)
            let maxLayer = self.drawGuideValue(value: highPrice, section: section, point: maxPoint!, trend: BMKLineChartItemTrend.up)
            serieLayer.addSublayer(maxLayer)
        }
        // 显示最小值
        if self.showMinVal && minValue != CGFloat.greatestFiniteMagnitude {
            let lowPrice = minValue.bm_toString(maxF: section.decimal)
            let minLayer = self.drawGuideValue(value: lowPrice, section: section, point: minPoint!, trend: BMKLineChartItemTrend.down)
            serieLayer.addSublayer(minLayer)
        }
        
        return serieLayer
    }
}

open class BMColumnModel: BMKLineChartModel {
    // MARK: - 交易量样式模型
    open override func drawSerie(seriesKey: String? = nil, _ startIndex: Int, endIndex: Int) -> CAShapeLayer {
        let serieLayer = CAShapeLayer()
        let modelLayer = CAShapeLayer()
        
        let plotWidth = (self.section.frame.size.width - self.section.padding.left - self.section.padding.right) / CGFloat(endIndex - startIndex)
        var plotPadding = plotWidth * self.plotPaddingExt
        plotPadding = plotPadding < 0.25 ? 0.25 : plotPadding
        
        let iybase = self.section.getY(with: section.yAxis.baseValue)
        
        for i in stride(from: startIndex, to: endIndex, by: 1) {
            if self.key != BMKLineSeriesKey.volume {
                if self[i].value == nil {
                    continue
                }
            }
            
            var isSolid = true
            let columnLayer = CAShapeLayer()
            
            let item = datas[i]

            let ix = self.section.frame.origin.x + self.section.padding.left + CGFloat(i - startIndex) * plotWidth
            let iyv = self.section.getY(with: item.vol)
            
            switch item.trend {
            case .up, .equal:
                columnLayer.strokeColor = self.upStyle.color.cgColor
                columnLayer.fillColor = self.upStyle.color.cgColor
                isSolid = self.upStyle.isSolid
            case .down:
                columnLayer.strokeColor = self.downStyle.color.cgColor
                columnLayer.fillColor = self.downStyle.color.cgColor
                isSolid = self.downStyle.isSolid
            }
            
            let columnPath = UIBezierPath(rect: CGRect(x: ix + plotPadding, y: iyv, width: plotWidth - 2 * plotPadding, height: iybase - iyv))
            columnLayer.path = columnPath.cgPath
            
            if isSolid {
                columnLayer.lineWidth = self.lineWidth
            } else {
                columnLayer.fillColor = UIColor.clear.cgColor
                columnLayer.lineWidth = self.lineWidth
            }
            
            modelLayer.addSublayer(columnLayer)
        }
        
        serieLayer.addSublayer(modelLayer)
        return serieLayer
    }
}

open class BMBarModel: BMKLineChartModel {
    // MARK: - 柱状样式模型
    open override func drawSerie(seriesKey: String? = nil, _ startIndex: Int, endIndex: Int) -> CAShapeLayer{
        let serieLayer = CAShapeLayer()
        let modelLayer = CAShapeLayer()
        
        let plotWidth = (self.section.frame.size.width - self.section.padding.left - self.section.padding.right) / CGFloat(endIndex - startIndex)
        var plotPadding = plotWidth * self.plotPaddingExt
        plotPadding = plotPadding < 0.25 ? 0.25 : plotPadding
        
        let iybase = self.section.getY(with: section.yAxis.baseValue)
        
        for i in stride(from: startIndex, to: endIndex, by: 1) {
            var isSolid = true
            let value = self[i].value
            if value == nil {
                continue
            }
            
            let barLayer = CAShapeLayer()
            
            let ix = self.section.frame.origin.x + self.section.padding.left + CGFloat(i - startIndex) * plotWidth
            let iyv = self.section.getY(with: value!)
            
            if value! > 0 {
                barLayer.strokeColor = self.upStyle.color.cgColor
                barLayer.fillColor = self.upStyle.color.cgColor
            } else {
                barLayer.strokeColor = self.downStyle.color.cgColor
                barLayer.fillColor = self.downStyle.color.cgColor
            }
            
            if i < endIndex - 1, let newValue = self[i + 1].value {
                if newValue >= value! {
                    isSolid = self.upStyle.isSolid
                } else {
                    isSolid = self.downStyle.isSolid
                }
            }
            
            if isSolid {
                barLayer.lineWidth = self.lineWidth
            } else {
                barLayer.fillColor = section.backgroundColor.cgColor
                barLayer.lineWidth = self.lineWidth
            }
            
            let barPath = UIBezierPath(rect: CGRect(x: ix + plotPadding, y: iyv, width: plotWidth - 2 * plotPadding, height: iybase - iyv))
            barLayer.path = barPath.cgPath
            
            modelLayer.addSublayer(barLayer)
        }
        
        serieLayer.addSublayer(modelLayer)
        return serieLayer
    }
}

open class BMRoundModel: BMKLineChartModel {
    // MARK: - 圆点样式模型
    open override func drawSerie(seriesKey: String? = nil, _ startIndex: Int, endIndex: Int) -> CAShapeLayer {
        let serieLayer = CAShapeLayer()
        
        let modelLayer = CAShapeLayer()
        modelLayer.strokeColor = self.upStyle.color.cgColor
        modelLayer.fillColor = UIColor.clear.cgColor
        modelLayer.lineWidth = self.lineWidth
        modelLayer.lineCap = CAShapeLayerLineCap.round
        modelLayer.lineJoin = CAShapeLayerLineJoin.bevel
        
        let plotWidth = (self.section.frame.size.width - self.section.padding.left - self.section.padding.right) / CGFloat(endIndex - startIndex)
        var plotPadding = plotWidth * self.plotPaddingExt
        plotPadding = plotPadding < 0.25 ? 0.25 : plotPadding
        
        var maxValue: CGFloat = 0
        var maxPoint: CGPoint?
        var minValue: CGFloat = CGFloat.greatestFiniteMagnitude
        var minPoint: CGPoint?
        
        for i in stride(from: startIndex, to: endIndex, by: 1) {
            guard let value = self[i].value else {
                continue
            }
            
            let item = datas[i]
            
            let ix = self.section.frame.origin.x + self.section.padding.left + CGFloat(i - startIndex) * plotWidth
            let iys = self.section.getY(with: value)
            
            let roundLayer = CAShapeLayer()
            let roundPoint = CGPoint(x: ix + plotPadding, y: iys)
            let roundSize = CGSize(width: plotWidth - 2 * plotPadding, height: plotWidth - 2 * plotPadding)
            let roundPath = UIBezierPath(ovalIn: CGRect(origin: roundPoint, size: roundSize))
            roundLayer.lineWidth = self.lineWidth
            roundLayer.path = roundPath.cgPath
            
            var fillColor: (color: UIColor, isSolid: Bool)
            if item.closePrice > value {
                fillColor = self.upStyle
            } else {
                fillColor = self.downStyle
            }
            
            roundLayer.strokeColor = fillColor.color.cgColor
            roundLayer.fillColor = fillColor.color.cgColor
            
            if !fillColor.isSolid {
                roundLayer.fillColor = section.backgroundColor.cgColor
            }
            
            modelLayer.addSublayer(roundLayer)
            
            if value > maxValue {
                maxValue = value
                maxPoint = roundPoint
            }
            
            if value < minValue {
                minValue = value
                minPoint = roundPoint
            }
        }
        
        serieLayer.addSublayer(modelLayer)
        
        if self.showMaxVal && maxValue != 0 {
            let highPrice = maxValue.bm_toString(maxF: section.decimal)
            let maxLayer = self.drawGuideValue(value: highPrice, section: section, point: maxPoint!, trend: BMKLineChartItemTrend.up)
            serieLayer.addSublayer(maxLayer)
        }
        
        if self.showMinVal && minValue != CGFloat.greatestFiniteMagnitude {
            let lowPrice = minValue.bm_toString(maxF: section.decimal)
            let minLayer = self.drawGuideValue(value: lowPrice, section: section, point: minPoint!, trend: BMKLineChartItemTrend.down)
            serieLayer.addSublayer(minLayer)
        }
        
        return serieLayer
    }
}

public extension BMKLineChartModel {
    // MARK: - 绘画最大最小值
    func drawGuideValue(value: String, section: BMKLineSection, point: CGPoint, trend: BMKLineChartItemTrend) -> CAShapeLayer {
        let guideValueLayer = CAShapeLayer()
        
        let fontSize = value.bm_sizeWithConstrained(section.labelFont)
        let arrowLineWidth: CGFloat = 4
        var isUp: CGFloat = -1
        var isLeft: CGFloat = -1
        var tagStartY: CGFloat = 0
        var isShowValue: Bool = true // 是否显示值, 圆形样式可以不显示值, 只显示圆形
        var guideValueTextColor: UIColor = UIColor.white
        var maxPriceStartX = point.x + arrowLineWidth * 2
        var maxPriceStartY: CGFloat = 0
        if maxPriceStartX + fontSize.width > section.frame.origin.x + section.frame.size.width - section.padding.right { // 如果超过了最右边界, 那么反方向画
            isLeft = -1
            maxPriceStartX = point.x + arrowLineWidth * isLeft * 2 - fontSize.width
        } else {
            isLeft = 1
        }
        
        var fillColor: UIColor = self.upStyle.color
        switch trend {
        case .up:
            fillColor = self.upStyle.color
            isUp = -1
            tagStartY = point.y - (fontSize.height + arrowLineWidth)
            maxPriceStartY = point.y - (fontSize.height + arrowLineWidth / 2)
        case .down:
            fillColor = self.downStyle.color
            isUp = 1
            tagStartY = point.y
            maxPriceStartY = point.y + arrowLineWidth / 2
        default:
            break
        }
        
        // 根据样式类型绘制
        switch self.ultimateValueStyle {
        case let .arrow(color):
            let arrowPath = UIBezierPath()
            let arrowLayer = CAShapeLayer()
            
            guideValueTextColor = color
            
            arrowPath.move(to: CGPoint(x: point.x, y: point.y + arrowLineWidth * isUp))
            arrowPath.addLine(to: CGPoint(x: point.x + arrowLineWidth * isLeft, y: point.y + arrowLineWidth * isUp))
            
            arrowPath.move(to: CGPoint(x: point.x, y: point.y + arrowLineWidth * isUp))
            arrowPath.addLine(to: CGPoint(x: point.x, y: point.y + arrowLineWidth * isUp * 2))
            
            arrowPath.move(to: CGPoint(x: point.x, y: point.y + arrowLineWidth * isUp))
            arrowPath.addLine(to: CGPoint(x: point.x + arrowLineWidth * isLeft, y: point.y + arrowLineWidth * isUp * 2))
            
            arrowLayer.path = arrowPath.cgPath
            arrowLayer.strokeColor = self.titleColor.cgColor
            
            guideValueLayer.addSublayer(arrowLayer)
            
        case let .tag(color):
            let tagLayer = CAShapeLayer()
            let arrowLayer = CAShapeLayer()
            
            guideValueTextColor = color
            
            let arrowPath = UIBezierPath()
            arrowPath.move(to: CGPoint(x: point.x, y: point.y + arrowLineWidth * isUp))
            arrowPath.addLine(to: CGPoint(x: point.x + arrowLineWidth * isLeft * 2, y: point.y + arrowLineWidth * isUp))
            arrowPath.addLine(to: CGPoint(x: point.x + arrowLineWidth * isLeft * 2, y: point.y + arrowLineWidth * isUp * 3))
            arrowPath.close()
            arrowLayer.path = arrowPath.cgPath
            arrowLayer.fillColor = fillColor.cgColor
            guideValueLayer.addSublayer(arrowLayer)
            
            let tagPath = UIBezierPath(roundedRect: CGRect(x: maxPriceStartX - arrowLineWidth,
                                                           y: tagStartY,
                                                           width: fontSize.width + arrowLineWidth * 2,
                                                           height: fontSize.height + arrowLineWidth),
                                       cornerRadius: arrowLineWidth * 2)
            tagLayer.path = tagPath.cgPath
            tagLayer.fillColor = fillColor.cgColor
            guideValueLayer.addSublayer(tagLayer)
            
        case let .circle(color, show):
            let circleLayer = CAShapeLayer()
            
            guideValueTextColor = color
            isShowValue = show
            
            let circleWidth: CGFloat = 6
            let circlePoint = CGPoint(x: point.x - circleWidth / 2, y: point.y - circleWidth / 2)
            let circleSize = CGSize(width: circleWidth, height: circleWidth)
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: circlePoint, size: circleSize))
            circleLayer.lineWidth = self.lineWidth
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = self.section.backgroundColor.cgColor
            circleLayer.strokeColor = fillColor.cgColor
            guideValueLayer.addSublayer(circleLayer)
            
        default:
            isShowValue = false
            break
        }
        
        if isShowValue {
            let textSize = value.bm_sizeWithConstrained(section.labelFont)
            let valueText = BMKLineTextLayer()
            valueText.frame = CGRect(origin: CGPoint(x: maxPriceStartX, y: maxPriceStartY), size: textSize)
            valueText.string = value
            valueText.fontSize = section.labelFont.pointSize
            valueText.foregroundColor =  guideValueTextColor.cgColor
            valueText.backgroundColor = UIColor.clear.cgColor
            valueText.contentsScale = UIScreen.main.scale
            guideValueLayer.addSublayer(valueText)
        }
        
        return guideValueLayer
    }
}

extension BMKLineChartModel {
    // MARK: - 样式工厂方法
    
    /// 生成点线样式
    public class func getLine(
        _ color: UIColor,
        title: String,
        key: String
        ) -> BMLineModel
    {
        let model = BMLineModel(
            upStyle: (color, true),
            downStyle: (color, true),
            titleColor: color
        )
        model.title = title
        model.key = key
        return model
    }
    
    /// 生成蜡烛样式
    public class func getCandle(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        titleColor: UIColor,
        key: String = BMKLineSeriesKey.candle
        ) -> BMCandleModel
    {
        let model = BMCandleModel(
            upStyle: upStyle,
            downStyle: downStyle,
            titleColor: titleColor
        )
        model.key = key
        return model
    }
    
    /// 生成交易量样式
    public class func getVolume(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        key: String = BMKLineSeriesKey.volume
        ) -> BMColumnModel
    {
        let model = BMColumnModel(
            upStyle: upStyle,
            downStyle: downStyle,
            titleColor: UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        )
        model.title = NSLocalizedString("Vol", comment: "")
        model.key = key
        return model
    }
    
    /// 生成柱状样式
    public class func getBar(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        titleColor: UIColor, title: String, key: String
        ) -> BMBarModel
    {
        let model = BMBarModel(
            upStyle: upStyle,
            downStyle: downStyle,
            titleColor: titleColor
        )
        model.title = title
        model.key = key
        return model
    }
    
    /// 生成圆点样式
    public class func getRound(
        upStyle: (color: UIColor, isSolid: Bool),
        downStyle: (color: UIColor, isSolid: Bool),
        titleColor: UIColor, title: String,
        plotPaddingExt: CGFloat,
        key: String
        ) -> BMRoundModel
    {
        let model = BMRoundModel(
            upStyle: upStyle,
            downStyle: downStyle,
            titleColor: titleColor, plotPaddingExt: plotPaddingExt
        )
        model.title = title
        model.key = key
        return model
    }
}

extension BMKLineChartModel {
    public subscript (index: Int) -> BMKLineChartItem {
        let item = self.datas[index]
        item.value = item.extVal[self.key]
        return item
    }
}
