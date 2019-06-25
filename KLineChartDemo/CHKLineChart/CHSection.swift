
import UIKit

/// 分区类型
///
/// - master: 主图
/// - assistant: 副图
public enum CHSectionValueType {
    case master
    case assistant
}

/// 分区
open class CHSection: NSObject {
    
    open var upColor: UIColor = UIColor.green
    open var downColor: UIColor = UIColor.red
    open var titleColor: UIColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    open var labelFont = UIFont.systemFont(ofSize: 10)
    open var valueType: CHSectionValueType = CHSectionValueType.master
    open var key = ""
    open var name: String = ""
    open var hidden: Bool = false
    open var paging: Bool = false
    open var selectedIndex: Int = 0
    open var padding: UIEdgeInsets = UIEdgeInsets.zero
    open var series = [CHSeries]()          // 每个分区包含多个系列, 每个系列包含多个点线模型
    open var tickInterval: Int = 0
    open var title: String = ""             // 标题
    open var titleShowOutSide: Bool = false // 标题是否显示在外面
    open var showTitle: Bool = true         // 是否显示标题
    open var decimal: Int = 2               // 保留小数几位
    open var ratios: Int = 0                // 分区所占图表的比列, 0代表不使用比列，采用固定高度
    open var fixHeight: CGFloat = 0         // 固定高度, 0则通过 ratio 计算高度
    open var frame: CGRect = CGRect.zero
    open var yAxis: CHYAxis = CHYAxis()     // Y轴参数
    open var xAxis: CHXAxis = CHXAxis()     // X轴参数
    open var backgroundColor: UIColor = UIColor.black
    open var index: Int = 0
    var titleLayer: CHShapeLayer = CHShapeLayer()   // 标题的绘图层
    var sectionLayer: CHShapeLayer = CHShapeLayer() // 分区的绘图层
    var titleView: UIView?                          // 用户自定义视图
    
    convenience init(valueType: CHSectionValueType, key: String = "") {
        self.init()
        
        self.valueType = valueType
        self.key = key
    }
}

extension CHSection {
    
    /// 清空图表的子图层
    func removeSublayers() {
        _ = self.sectionLayer.sublayers?.map { $0.removeFromSuperlayer() }
        self.sectionLayer.sublayers?.removeAll()
        
        _ = self.titleLayer.sublayers?.map { $0.removeFromSuperlayer() }
        self.titleLayer.sublayers?.removeAll()
    }
    
    /// 建立Y轴左边对象
    func buildYAxisPerModel(_ model: CHChartModel, startIndex: Int, endIndex: Int) {
        let datas = model.datas
        if datas.count == 0 {
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
            
            switch model {
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
                let value = model[i].value
                if value == nil {
                    continue
                }
                if value! > self.yAxis.max {
                    self.yAxis.max = value!
                }
                if value! < self.yAxis.min {
                    self.yAxis.min = value!
                }
            case is CHColumnModel:
                let value = item.vol
                if value > self.yAxis.max {
                    self.yAxis.max = value
                }
                if value < self.yAxis.min {
                    self.yAxis.min = value
                }
            default:
                break
            }
        }
    }
    
    /// 绘制 header 上的标题信息
    ///
    /// - Parameter title: 标题富文本
    func drawTitleForHeader(title: NSAttributedString) {
        guard self.showTitle else {
            return
        }
        _ = self.titleLayer.sublayers?.map { $0.removeFromSuperlayer() }
        self.titleLayer.sublayers?.removeAll()
        
        var yPos: CGFloat = 0
        var containerWidth: CGFloat = 0
        let textSize = title.string.ch_sizeWithConstrained(self.labelFont, constraintRect: CGSize(width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
        
        if titleShowOutSide {
            yPos = self.frame.origin.y - textSize.height - 4
            containerWidth = self.frame.width
        } else {
            yPos = self.frame.origin.y + 2
            containerWidth = self.frame.width - self.padding.left - self.padding.right
        }
        
        let startX = self.frame.origin.x + self.padding.left + 2
        let point = CGPoint(x: startX, y: yPos)
        
        let titleText = CHTextLayer()
        titleText.frame = CGRect(origin: point, size: CGSize(width: containerWidth, height: textSize.height + 20))
        //titleText.foregroundColor =  self.titleColor.cgColor
        titleText.string = title
        titleText.fontSize = self.labelFont.pointSize
        titleText.backgroundColor = UIColor.clear.cgColor
        titleText.contentsScale = UIScreen.main.scale
        titleText.isWrapped = true
        
        self.titleLayer.addSublayer(titleText)
    }
    
    // 切换到下一个系列
    func nextPage() {
        if self.selectedIndex < self.series.count - 1 {
            self.selectedIndex += 1
        } else {
            self.selectedIndex = 0
        }
    }
}

// MARK: - Public Methods
extension CHSection {
    
    /// 建立Y轴的数值范围
    ///
    /// - Parameters:
    ///   - startIndex: 计算范围的开始数据点
    ///   - endIndex: 计算范围的结束数据点
    ///   - datas: 数据集合
    public func buildYAxis(startIndex: Int, endIndex: Int, datas: [CHChartItem]) {
        self.yAxis.isUsed = false
        var baseValueSticky = false
        var symmetrical = false
        if self.paging { // 分页, 计算当前选中系列作为坐标系的数据源
            let serie = self.series[self.selectedIndex]
            baseValueSticky = serie.baseValueSticky
            symmetrical = serie.symmetrical
            for serieModel in serie.chartModels {
                serieModel.datas = datas
                self.buildYAxisPerModel(serieModel, startIndex: startIndex, endIndex: endIndex)
            }
        } else {
            for serie in self.series { // 不分页, 计算所有系列作为坐标系的数据源
                if serie.hidden {
                    continue
                }
                baseValueSticky = serie.baseValueSticky
                symmetrical = serie.symmetrical
                for serieModel in serie.chartModels {
                    serieModel.datas = datas
                    self.buildYAxisPerModel(serieModel, startIndex: startIndex, endIndex: endIndex)
                }
            }
        }
        
        // 让边界溢出些, 这样图表不会占满屏幕
        //self.yAxis.max += (self.yAxis.max - self.yAxis.min) * self.yAxis.ext
        //self.yAxis.min -= (self.yAxis.max - self.yAxis.min) * self.yAxis.ext
        
        if !baseValueSticky { // 不使用固定基值
            if self.yAxis.max >= 0 && self.yAxis.min >= 0 {
                self.yAxis.baseValue = self.yAxis.min
            } else if self.yAxis.max < 0 && self.yAxis.min < 0 {
                self.yAxis.baseValue = self.yAxis.max
            } else {
                self.yAxis.baseValue = 0
            }
        } else { // 使用固定基值
            if self.yAxis.baseValue < self.yAxis.min {
                self.yAxis.min = self.yAxis.baseValue
            }
            
            if self.yAxis.baseValue > self.yAxis.max {
                self.yAxis.max = self.yAxis.baseValue
            }
        }
        
        // 如果使用水平对称显示Y轴, 则基于基值计算上下的边界值
        if symmetrical {
            if self.yAxis.baseValue > self.yAxis.max {
                self.yAxis.max = self.yAxis.baseValue + (self.yAxis.baseValue - self.yAxis.min)
            } else if self.yAxis.baseValue < self.yAxis.min {
                self.yAxis.min =  self.yAxis.baseValue - (self.yAxis.max - self.yAxis.baseValue)
            } else {
                if (self.yAxis.max - self.yAxis.baseValue) > (self.yAxis.baseValue - self.yAxis.min) {
                    self.yAxis.min = self.yAxis.baseValue - (self.yAxis.max - self.yAxis.baseValue)
                } else {
                    self.yAxis.max = self.yAxis.baseValue + (self.yAxis.baseValue - self.yAxis.min)
                }
            }
        }
    }
    
    /// 获取标签值对应在坐标系中的Y值
    ///
    /// - Parameter val: 标签值
    /// - Returns: 坐标系中实际的Y值
    public func getLocalY(_ val: CGFloat) -> CGFloat {
        let max = self.yAxis.max
        let min = self.yAxis.min
        if max == min {
            return 0
        }
        /**
         计算公式:
         Y轴有值的区间高度 = 整个分区高度 -（paddingTop + paddingBottom）
         当前Y值所在位置的比例 =（当前值 - Y最小值）/（Y最大值 - Y最小值）
         当前Y值实际的相对Y轴有值的区间的高度 = 当前Y值所在位置的比例 * Y轴有值的区间高度
         当前Y值的实际坐标 = 分区高度 + 分区Y坐标 - paddingBottom - 当前Y值实际的相对Y轴有值的区间的高度
         */
        let baseY = self.frame.size.height + self.frame.origin.y - self.padding.bottom - (self.frame.size.height - self.padding.top - self.padding.bottom) * (val - min) / (max - min)
        return baseY
    }
    
    /// 获取坐标系中Y值对应的标签值
    public func getRawValue(_ y: CGFloat) -> CGFloat {
        let max = self.yAxis.max
        let min = self.yAxis.min
        let ymax = self.getLocalY(self.yAxis.min) // 最大值对应Y轴最高点
        let ymin = self.getLocalY(self.yAxis.max) // 最小值对应Y轴最低点
        if max == min {
            return 0
        }
        let value = (y - ymax) / (ymin - ymax) * (max - min) + min
        return value
    }
    
    /// 绘制分区的标题
    public func drawTitle(_ chartSelectedIndex: Int) {
        guard self.showTitle else {
            return
        }
        if chartSelectedIndex == -1 {
            return
        }
        if self.paging {
            let series = self.series[self.selectedIndex]
            if let attributes = self.getTitleAttributesByIndex(chartSelectedIndex, series: series) {
                self.setHeader(titles: attributes)
            }
        } else {
            var titleAttributes = [(title: String, color: UIColor)]()
            for serie in self.series {
                if let attributes = self.getTitleAttributesByIndex(chartSelectedIndex, series: serie) {
                    titleAttributes.append(contentsOf: attributes)
                }
            }
            self.setHeader(titles: titleAttributes)
        }
    }
    
    /// 添加用户自定义的视图到主视图
    ///
    /// - Parameters:
    ///   - view: 自定义标题视图
    ///   - mainView: 主视图
    public func addCustomView(_ view: UIView, inView mainView: UIView) {
        if self.titleView !== view {
            self.titleView?.removeFromSuperview()
            self.titleView = nil
            
            var yPos: CGFloat = 0
            var containerWidth: CGFloat = 0
            if titleShowOutSide {
                yPos = self.frame.origin.y - self.padding.top
                containerWidth = self.frame.width
            } else {
                yPos = self.frame.origin.y
                containerWidth = self.frame.width - self.padding.left - self.padding.right
            }
            
            let startX = self.frame.origin.x + self.padding.left
            containerWidth = self.frame.width - self.padding.left - self.padding.right
            
            var frame = view.frame
            frame.origin.x = startX
            frame.origin.y = yPos
            frame.size.width = containerWidth
            view.frame = frame
            
            mainView.addSubview(view)
            self.titleView = view
        }
        mainView.bringSubviewToFront(self.titleView!)
    }
    
    /// 设置分区头部文本显示内容
    ///
    /// - Parameter titles: 文本及颜色元组
    public func setHeader(titles: [(title: String, color: UIColor)])  {
        var start = 0
        let titleString = NSMutableAttributedString()
        for (title, color) in titles {
            titleString.append(NSAttributedString(string: title))
            let range = NSMakeRange(start, title.ch_length)
            let colorAttribute = [NSAttributedString.Key.foregroundColor: color]
            titleString.addAttributes(colorAttribute, range: range)
            start += title.ch_length
        }
        self.drawTitleForHeader(title: titleString)
    }
    
    /// 根据 seriesKey 获取线段的标题
    public func getTitleAttributesByIndex(_ chartSelectedIndex: Int, seriesKey: String) -> [(title: String, color: UIColor)]? {
        guard let series = self.getSeries(key: seriesKey) else {
            return nil
        }
        return self.getTitleAttributesByIndex(chartSelectedIndex, series: series)
    }
    
    /// 获取标题属性元组
    ///
    /// - Parameters:
    ///   - chartSelectedIndex: 图表选中位置
    ///   - series: 线
    /// - Returns: 元祖
    public func getTitleAttributesByIndex(_ chartSelectedIndex: Int, series: CHSeries) -> [(title: String, color: UIColor)]? {
        if series.hidden {
            return nil
        }
        guard series.showTitle else {
            return nil
        }
        if chartSelectedIndex == -1 {
            return nil
        }
        
        var titleAttrs = [(title: String, color: UIColor)]()
        if !series.title.isEmpty {
            let seriesTitle = series.title + "  "
            titleAttrs.append((title: seriesTitle, color: self.titleColor))
        }
        
        for model in series.chartModels {
            let item = model[chartSelectedIndex]
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
    
    /// 根据键值查找线段
    public func getSeries(key: String) -> CHSeries? {
        var series: CHSeries?
        for s in self.series {
            if s.key == key {
                series = s
                break
            }
        }
        return series
    }
    
    /// 根据键值删除线段
    public func removeSeries(key: String) {
        for (index, s) in self.series.enumerated() {
            if s.key == key {
                self.series.remove(at: index)
                break
            }
        }
    }
}
