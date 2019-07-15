
import UIKit

/// 分区类型
///
/// - master: 主图
/// - assistant: 副图
public enum CHSectionType {
    case master
    case assistant
}

/// 分区
open class CHSection: NSObject {
    
    open var type: CHSectionType = .master
    
    open var key = ""
    open var name: String = ""
    
    open var seriesArray: [CHSeries] = []
    
    open var isHidden: Bool = false
    
    open var upColor = UIColor.green
    open var downColor = UIColor.red
    open var backgroundColor = UIColor.black
    
    open var labelFont = UIFont.systemFont(ofSize: 10)
    open var decimal: Int = 2 // 保留小数几位
    open var tickInterval: Int = 0
    
    open var titleText: String = ""
    open var titleColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    open var isShowTitleOutside: Bool = false
    open var isShowTitle: Bool = true
    
    open var isPageable: Bool = false
    open var selectedIndex: Int = 0
    open var index: Int = 0
    
    open var ratios: Int = 0         // 该分区占整个图表的比列, 0代表采用固定高度
    open var fixHeight: CGFloat = 0  // 固定高度, 0代表通过 ratios 计算高度
    open var frame: CGRect = CGRect.zero
    open var padding: UIEdgeInsets = UIEdgeInsets.zero
    
    open var yAxis: CHYAxis = CHYAxis()
    open var xAxis: CHXAxis = CHXAxis()
    
    var titleLayer: CHShapeLayer = CHShapeLayer()   // 标题的绘图层
    var titleView: UIView?                          // 用户自定义视图
    var sectionLayer: CHShapeLayer = CHShapeLayer() // 分区的绘图层
    var maskLayer: CAShapeLayer?                    // 分时线下面的渐变遮罩
    
    convenience init(type: CHSectionType, key: String = "") {
        self.init()
        
        self.type = type
        self.key = key
    }
}

extension CHSection {
    
    func removeSublayers() {
        self.sectionLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        self.sectionLayer.sublayers?.removeAll()
        
        self.titleLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        self.titleLayer.sublayers?.removeAll()
    }
    
    func nextPageSeries() {
        if self.selectedIndex < self.seriesArray.count - 1 {
            self.selectedIndex += 1
        } else {
            self.selectedIndex = 0
        }
    }
    
    /// 根据键值查找系列
    public func getSeries(key: String) -> CHSeries? {
        var series: CHSeries?
        for s in self.seriesArray {
            if s.key == key {
                series = s
                break
            }
        }
        return series
    }
    
    /// 根据键值删除系列
    public func removeSeries(key: String) {
        for (index, s) in self.seriesArray.enumerated() {
            if s.key == key {
                self.seriesArray.remove(at: index)
                break
            }
        }
    }
}

extension CHSection {
    /// 获取标签值对应在坐标系中的Y值
    public func getY(with value: CGFloat) -> CGFloat {
        let max = self.yAxis.max
        let min = self.yAxis.min
        if max == min {
            return 0
        }
        // Y 轴区间高度 = 分区高度 - paddingTop - paddingBottom
        let yAxisHeight = self.frame.size.height - self.padding.top - self.padding.bottom
        
        // 当前值所在位置的比例 =（当前值 - Y最小值）/（Y最大值 - Y最小值）
        let positionRatio = (value - min) / (max - min)
        
        // 当前值相对 Y 轴区间的高度 = 当前Y值所在位置的比例 * Y轴有值的区间高度
        let positionHeight = yAxisHeight * positionRatio
        
        // 当前Y值的实际坐标 = 分区高度 + 分区Y坐标 - paddingBottom - 当前值相对 Y 轴区间的高度
        let baseY = self.frame.size.height + self.frame.origin.y - self.padding.bottom - positionHeight
        
        return baseY
    }
    
    /// 获取坐标系中Y值对应的标签值
    public func getValue(with y: CGFloat) -> CGFloat {
        let max = self.yAxis.max
        let min = self.yAxis.min
        if max == min {
            return 0
        }
        let maxY = self.getY(with: self.yAxis.min) // 最大值对应Y轴最高点
        let minY = self.getY(with: self.yAxis.max) // 最小值对应Y轴最低点
        let value = (y - maxY) / (minY - maxY) * (max - min) + min
        return value
    }
}

extension CHSection {
    
    public func drawTitle(_ selectedPointIndex: Int) {
        guard self.isShowTitle else {
            return
        }
        if selectedPointIndex == -1 {
            return
        }
        if self.isPageable {
            let series = self.seriesArray[self.selectedIndex]
            if let titlesAndAttrs = self.getTitlesAndAttributesByIndex(selectedPointIndex, series: series) {
                self.prepareDrawTitle(titlesAndAttributes: titlesAndAttrs)
            }
        } else {
            var titlesAndAttrs = [(title: String, color: UIColor)]()
            for series in self.seriesArray {
                if let titlesAndAttrsTemp = self.getTitlesAndAttributesByIndex(selectedPointIndex, series: series) {
                    titlesAndAttrs.append(contentsOf: titlesAndAttrsTemp)
                }
            }
            self.prepareDrawTitle(titlesAndAttributes: titlesAndAttrs)
        }
    }
    
    public func getTitlesAndAttributesByIndex(_ selectedPointIndex: Int, seriesKey: String) -> [(title: String, color: UIColor)]? {
        guard let series = self.getSeries(key: seriesKey) else {
            return nil
        }
        return self.getTitlesAndAttributesByIndex(selectedPointIndex, series: series)
    }
    
    public func getTitlesAndAttributesByIndex(_ selectedPointIndex: Int, series: CHSeries) -> [(title: String, color: UIColor)]? {
        guard !series.hidden else {
            return nil
        }
        guard series.showTitle else {
            return nil
        }
        guard selectedPointIndex != -1 else {
            return nil
        }
        
        var titleAttrs = [(title: String, color: UIColor)]()
        if !series.title.isEmpty {
            let seriesTitle = series.title + "  "
            titleAttrs.append((title: seriesTitle, color: self.titleColor))
        }
        
        for model in series.chartModels {
            let item = model[selectedPointIndex]
            var title = ""
            switch model {
            case is CHCandleModel:
                if model.key != CHSeriesKey.candle {
                    continue
                }
                var amplitude: CGFloat = 0
                if item.openPrice > 0 {
                    amplitude = (item.closePrice - item.openPrice) / item.openPrice * 100
                }
                title += NSLocalizedString("O", comment: "") + ": " +
                    item.openPrice.ch_toString(maxF: self.decimal) + "  "
                title += NSLocalizedString("H", comment: "") + ": " +
                    item.highPrice.ch_toString(maxF: self.decimal) + "  "
                title += NSLocalizedString("L", comment: "") + ": " +
                    item.lowPrice.ch_toString(maxF: self.decimal) + "  "
                title += NSLocalizedString("C", comment: "") + ": " +
                    item.closePrice.ch_toString(maxF: self.decimal) + "  "
                title += NSLocalizedString("R", comment: "") + ": " +
                    amplitude.ch_toString(maxF: self.decimal) + "%   "
            case is CHColumnModel:
                if model.key != CHSeriesKey.volume {
                    continue
                }
                title += model.title + ": " + item.vol.ch_toString(maxF: self.decimal) + "  "
            default:
                if item.value != nil {
                    title += model.title + ": " + item.value!.ch_toString(maxF: self.decimal) + "  "
                }  else {
                    title += model.title + ": --  "
                }
            }
            var textColor: UIColor
            if model.useTitleColor {
                textColor = model.titleColor
            } else {
                switch item.trend {
                case .up, .equal:
                    textColor = model.upStyle.color
                case .down:
                    textColor = model.downStyle.color
                }
            }
            titleAttrs.append((title: title, color: textColor))
        }
        return titleAttrs
    }
    
    public func prepareDrawTitle(titlesAndAttributes: [(title: String, color: UIColor)])  {
        var start = 0
        let titleString = NSMutableAttributedString()
        for (title, color) in titlesAndAttributes {
            titleString.append(NSAttributedString(string: title))
            let range = NSMakeRange(start, title.ch_length)
            let colorAttribute = [NSAttributedString.Key.foregroundColor: color]
            titleString.addAttributes(colorAttribute, range: range)
            start += title.ch_length
        }
        self.drawTitleForHeader(title: titleString)
    }
    
    func drawTitleForHeader(title: NSAttributedString) {
        guard self.isShowTitle else {
            return
        }
        self.titleLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        self.titleLayer.sublayers?.removeAll()
        
        var yLocation: CGFloat = 0
        var containerWidth: CGFloat = 0
        let textSize = title.string.ch_sizeWithConstrained(self.labelFont, constraintRect: CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
        
        if isShowTitleOutside {
            yLocation = self.frame.origin.y - textSize.height - 4
            containerWidth = self.frame.width
        } else {
            yLocation = self.frame.origin.y + 2
            containerWidth = self.frame.width - self.padding.left - self.padding.right
        }
        
        let xLocation = self.frame.origin.x + self.padding.left + 2
        let point = CGPoint(x: xLocation, y: yLocation)
        
        let titleText = CHTextLayer()
        titleText.frame = CGRect(origin: point, size: CGSize(width: containerWidth, height: textSize.height + 20))
        //titleText.foregroundColor = self.titleColor.cgColor
        titleText.backgroundColor = UIColor.clear.cgColor
        titleText.string = title
        titleText.fontSize = self.labelFont.pointSize
        titleText.contentsScale = UIScreen.main.scale
        titleText.isWrapped = true
        self.titleLayer.addSublayer(titleText)
    }
    
    public func drawCustomTitleForHeader(_ titleView: UIView, inView chartView: UIView) {
        if self.titleView !== titleView {
            self.titleView?.removeFromSuperview()
            self.titleView = nil
            
            var yLocation: CGFloat = 0
            var containerWidth: CGFloat = 0
            if isShowTitleOutside {
                yLocation = self.frame.origin.y - self.padding.top
                containerWidth = self.frame.width
            } else {
                yLocation = self.frame.origin.y
                containerWidth = self.frame.width - self.padding.left - self.padding.right
            }
            
            let xLocation = self.frame.origin.x + self.padding.left
            containerWidth = self.frame.width - self.padding.left - self.padding.right
            
            var frame = titleView.frame
            frame.origin.x = xLocation
            frame.origin.y = yLocation
            frame.size.width = containerWidth
            titleView.frame = frame
            
            chartView.addSubview(titleView)
            self.titleView = titleView
        }
        chartView.bringSubviewToFront(self.titleView!)
    }
}

extension CHSection {
    
    /// 建立Y坐标轴
    ///
    /// - Parameters:
    ///   - startIndex: 开始数据点
    ///   - endIndex: 结束数据点
    ///   - datas: 数据集合
    func buildYAxis(startIndex: Int, endIndex: Int, datas: [CHChartItem]) {
        self.yAxis.isUsed = false
        var baseValueSticky = false
        var symmetrical = false
        if self.isPageable { // 分页, 只计算当前选中系列
            let series = self.seriesArray[self.selectedIndex]
            baseValueSticky = series.baseValueSticky
            symmetrical = series.symmetrical
            for chartModel in series.chartModels {
                chartModel.datas = datas
                self.calculateYAxis(with: chartModel, startIndex: startIndex, endIndex: endIndex)
            }
        } else {
            for series in self.seriesArray { // 不分页, 计算所有系列
                if series.hidden { continue }
                baseValueSticky = series.baseValueSticky
                symmetrical = series.symmetrical
                for chartModel in series.chartModels {
                    chartModel.datas = datas
                    self.calculateYAxis(with: chartModel, startIndex: startIndex, endIndex: endIndex)
                }
            }
        }
        
        // 让边界溢出些, 避免图表占满屏幕
        //self.yAxis.max += (self.yAxis.max - self.yAxis.min) * self.yAxis.ext
        //self.yAxis.min -= (self.yAxis.max - self.yAxis.min) * self.yAxis.ext
        
        if baseValueSticky { // 使用固定基值
            if self.yAxis.baseValue < self.yAxis.min {
                self.yAxis.min = self.yAxis.baseValue
            }
            if self.yAxis.baseValue > self.yAxis.max {
                self.yAxis.max = self.yAxis.baseValue
            }
        } else { // 不使用固定基值
            if self.yAxis.max >= 0 && self.yAxis.min >= 0 {
                self.yAxis.baseValue = self.yAxis.min
            } else if self.yAxis.max < 0 && self.yAxis.min < 0 {
                self.yAxis.baseValue = self.yAxis.max
            } else {
                self.yAxis.baseValue = 0
            }
        }
        
        if symmetrical { // 如果水平对称显示Y轴坐标, 则基于基值计算上下的边界值
            if self.yAxis.baseValue > self.yAxis.max {
                self.yAxis.max = self.yAxis.baseValue + (self.yAxis.baseValue - self.yAxis.min)
            } else if self.yAxis.baseValue < self.yAxis.min {
                self.yAxis.min = self.yAxis.baseValue - (self.yAxis.max - self.yAxis.baseValue)
            } else {
                if (self.yAxis.max - self.yAxis.baseValue) > (self.yAxis.baseValue - self.yAxis.min) {
                    self.yAxis.min = self.yAxis.baseValue - (self.yAxis.max - self.yAxis.baseValue)
                } else {
                    self.yAxis.max = self.yAxis.baseValue + (self.yAxis.baseValue - self.yAxis.min)
                }
            }
        }
    }
    
    func calculateYAxis(with chartModel: CHChartModel, startIndex: Int, endIndex: Int) {
        let datas = chartModel.datas
        guard datas.count > 0 else {
            return
        }
        
        if !self.yAxis.isUsed {
            self.yAxis.decimal = self.decimal
            self.yAxis.max = 0
            self.yAxis.min = CGFloat.greatestFiniteMagnitude
            self.yAxis.isUsed = true
        }
        
        for i in stride(from: startIndex, to: endIndex, by: 1) {
            let item = datas[i]
            
            switch chartModel {
            case is CHCandleModel:
                let high = item.highPrice
                let low = item.lowPrice
                if high > self.yAxis.max {
                    self.yAxis.max = high
                }
                if low < self.yAxis.min {
                    self.yAxis.min = low
                }
            case is CHLineModel, is CHBarModel:
                if let value = chartModel[i].value {
                    if value > self.yAxis.max {
                        self.yAxis.max = value
                    }
                    if value < self.yAxis.min {
                        self.yAxis.min = value
                    }
                }
            case is CHColumnModel:
                let vol = item.vol
                if vol > self.yAxis.max {
                    self.yAxis.max = vol
                }
                if vol < self.yAxis.min {
                    self.yAxis.min = vol
                }
            default:
                break
            }
        }
    }
}
