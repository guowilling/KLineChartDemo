
import UIKit

/// 图表刷新后滚动到开始显示的位置
///
/// - head: 头部
/// - tail: 尾部
/// - none: 不处理
public enum BMKLineChartViewScrollPosition {
    case head, tail, none
}

/// 图表选中时十字 Y 轴显示位置
///
/// - free: 显示在选中点
/// - onClosePrice: 显示在收盘价
public enum BMKLineChartSelectedPosition {
    case free
    case onClosePrice
}

@objc public protocol BMKLineChartDelegate: class {
    
    func numberOfPointsInKLineChart(chart: BMKLineChartView) -> Int
    
    func kLineChart(chart: BMKLineChartView, valueForPointAtIndex index: Int) -> BMKLineChartItem
    
    /// 图表 Y 轴的显示的内容
    func kLineChart(chart: BMKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: BMKLineSection) -> String
    
    /// 图表 X 轴的显示的内容
    @objc optional func kLineChart(chart: BMKLineChartView, labelOnXAxisForIndex index: Int) -> String
    
    /// 配置各个分区小数位保留数
    @objc optional func kLineChart(chart: BMKLineChartView, decimalAt section: Int) -> Int
    
    /// 设置 Y 轴标签的宽度
    @objc optional func widthForYAxisLabelInKLineChart(in chart: BMKLineChartView) -> CGFloat
    
    /// 设置 X 轴标签的高度
    @objc optional func heightForXAxisInKLineChart(in chart: BMKLineChartView) -> CGFloat
    
    /// 响应点击图表事件
    @objc optional func kLineChart(chart: BMKLineChartView, didSelectAt index: Int, item: BMKLineChartItem)
    
    /// 初始化图表时的显示范围长度
    @objc optional func initialRangeInKLineChart(in chart: BMKLineChartView) -> Int
    
    /// 自定义选择点时出现的标签样式
    @objc optional func kLineChart(chart: BMKLineChartView, labelOfYAxis yAxis: UILabel, labelOfXAxis: UILabel)
    
    /// 自定义分区的头部视图
    @objc optional func kLineChart(chart: BMKLineChartView, viewForHeaderInSection section: Int) -> UIView?
    
    /// 自定义分区的头部显示内容
    @objc optional func kLineChart(chart: BMKLineChartView, titleForHeaderInSection section: BMKLineSection, index: Int, item: BMKLineChartItem) -> NSAttributedString?
    
    @objc optional func kLineChart(chart: BMKLineChartView, didFlipPageSeries section: BMKLineSection, series: BMKLineSeries, seriesIndex: Int)
    
    @objc optional func didFinishKLineChartRefresh(chart: BMKLineChartView)
}

open class BMKLineChartView: UIView {
    
    let MinRange = 15
    let MaxRange = 150
    
    public let DefaultYAxisLabelWidth: CGFloat = 50
    public let DefaultXAxisHegiht: CGFloat = 20
    
    @IBInspectable open var upColor: UIColor = UIColor.green
    @IBInspectable open var downColor: UIColor = UIColor.red
    @IBInspectable open var labelFont = UIFont.systemFont(ofSize: 10) 
    @IBInspectable open var lineColor: UIColor = UIColor(white: 0.2, alpha: 1)
    @IBInspectable open var textColor: UIColor = UIColor(white: 0.8, alpha: 1)
    @IBInspectable open var xAxisPerInterval: Int = 4
    
    @IBOutlet open weak var delegate: BMKLineChartDelegate?
    
    open var algorithms: [BMKLineIndexAlgorithmProtocol] = []
    
    open var yAxisLabelWidth: CGFloat = 0
    
    open var padding: UIEdgeInsets = UIEdgeInsets.zero
    
    open var yAxisShowPosition = BMKLineYAxisShowPosition.right
    
    open var isInnerYAxis: Bool = false
    
    open var selectedPosition: BMKLineChartSelectedPosition = .onClosePrice
    
    open var scrollToPosition: BMKLineChartViewScrollPosition = .none
    
    open var sections:[BMKLineSection] = []
    
    open var selectedPointIndex: Int = -1
    
    var selectedPoint: CGPoint = CGPoint.zero
    open var enablePinch: Bool = true
    open var enablePan: Bool = true
    open var enableTap: Bool = true {
        didSet {
            self.showSelection = self.enableTap
        }
    }
    open var panShouldMoveChart: Bool = false
    
    open var showSelection: Bool = true {
        didSet {
            self.selectedXAxisLabel?.isHidden = !self.showSelection
            self.selectedYAxisLabel?.isHidden = !self.showSelection
            self.verticalLineView?.isHidden = !self.showSelection
            self.horizontalLineView?.isHidden = !self.showSelection
            self.sightView?.isHidden = !self.showSelection
        }
    }
    
    open var showXAxisOnSection: Int = -1
    
    open var isShowXAxisLabel: Bool = true
    
    open var isShowPlotAll: Bool = false
    
    open var borderWidth: (top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) = (0.25, 0.25, 0.25, 0.25)
    
    var borderColor: UIColor = UIColor.gray
    
    var lineWidth: CGFloat = 0.5
    
    var plotCount: Int = 0
    
    var rangeFrom: Int = 0
    var rangeTo: Int = 0
    open var range: Int = 75
    
    open var labelSize = CGSize(width: 30, height: 15)
    
    var datas: [BMKLineChartItem] = []
    
    open var selectedBGColor: UIColor = UIColor(white: 0.4, alpha: 1)    
    open var selectedTextColor: UIColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
    
    var verticalLineView: UIView?
    var horizontalLineView: UIView?
    var selectedXAxisLabel: UILabel?
    var selectedYAxisLabel: UILabel?
    var sightView: UIView?
    
    lazy var dynamicAnimator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self)
    
    lazy var dynamicItem = BMKLineDynamicItem()
    
    /// 用于处理滚动图表时的线性减速行为
    weak var decelerationBehavior: UIDynamicItemBehavior?
    /// 减速起始 X
    var decelerationStartX: CGFloat = 0
    
    /// 用于处理滚动释放后图表的反弹行为
    weak var springBehavior: UIAttachmentBehavior?
    
    /// 图表绘制层
    var drawLayer: BMKLineShapeLayer = BMKLineShapeLayer()
    
    open var style: BMKLineChartStyle! {
        didSet {
            // SRTEST
            self.backgroundColor = self.style.backgroundColor
//            self.backgroundColor = UIColor.random
            self.sections = self.style.sections
            self.padding = self.style.padding
            self.algorithms = self.style.algorithms
            self.lineColor = self.style.lineColor
            self.textColor = self.style.textColor
            self.labelFont = self.style.labelFont
            self.yAxisShowPosition = self.style.yAxisShowPosition
            self.selectedBGColor = self.style.selectedBGColor
            self.selectedTextColor = self.style.selectedTextColor
            self.isInnerYAxis = self.style.isInnerYAxis
            self.enableTap = self.style.enableTap
            self.enablePinch = self.style.enablePinch
            self.enablePan = self.style.enablePan
            self.showSelection = self.style.showSelection
            self.showXAxisOnSection = self.style.showXAxisOnSection
            self.isShowPlotAll = self.style.isShowPlotAll
            self.isShowXAxisLabel = self.style.showXAxisLabel
            self.borderWidth = self.style.borderWidth
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupUI()
    }

    fileprivate func setupUI() {
        self.isMultipleTouchEnabled = true
        
        // 显示辅助视图
        self.verticalLineView = UIView(frame: CGRect(x: 0, y: 0, width: lineWidth, height: 0))
        self.verticalLineView?.backgroundColor = self.selectedBGColor
        self.verticalLineView?.isHidden = true
        self.addSubview(self.verticalLineView!)
        
        self.horizontalLineView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: lineWidth))
        self.horizontalLineView?.backgroundColor = self.selectedBGColor
        self.horizontalLineView?.isHidden = true
        self.addSubview(self.horizontalLineView!)
        
        self.selectedYAxisLabel = UILabel(frame: CGRect.zero)
        self.selectedYAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedYAxisLabel?.textColor = self.selectedTextColor
        self.selectedYAxisLabel?.textAlignment = NSTextAlignment.center
        self.selectedYAxisLabel?.font = self.labelFont
        self.selectedYAxisLabel?.minimumScaleFactor = 0.5
        self.selectedYAxisLabel?.adjustsFontSizeToFitWidth = true
        self.selectedYAxisLabel?.lineBreakMode = .byClipping
        self.selectedYAxisLabel?.isHidden = true
        self.addSubview(self.selectedYAxisLabel!)
        
        self.selectedXAxisLabel = UILabel(frame: CGRect.zero)
        self.selectedXAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedXAxisLabel?.textColor = self.selectedTextColor
        self.selectedXAxisLabel?.textAlignment = NSTextAlignment.center
        self.selectedXAxisLabel?.font = self.labelFont
        self.selectedXAxisLabel?.isHidden = true
        self.addSubview(self.selectedXAxisLabel!)
        
        self.sightView = UIView(frame: CGRect(x: 0, y: 0, width: 7.5, height: 7.5))
        self.sightView?.backgroundColor = self.selectedBGColor
        self.sightView?.isHidden = true
        self.sightView?.layer.cornerRadius = 3
        self.addSubview(self.sightView!)
        
        // 绘制层
        self.layer.addSublayer(self.drawLayer)
        
        // 手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(doTapAction(_:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(doPanAction(_:)))
        pan.delegate = self
        self.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(doPinchAction(_:)))
        pinch.delegate = self
        self.addGestureRecognizer(pinch)
        
        if let range = self.delegate?.initialRangeInKLineChart?(in: self) {
            self.range = range
        }
        
        self.resetData()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // 布局完成重绘
        self.drawLayerView()
    }
    
    fileprivate func resetData() {
        self.datas.removeAll()
        self.plotCount = self.delegate?.numberOfPointsInKLineChart(chart: self) ?? 0
        if plotCount > 0 {
            for i in 0...self.plotCount - 1 {
                let item = self.delegate?.kLineChart(chart: self, valueForPointAtIndex: i)
                self.datas.append(item!)
            }
            for algorithm in self.algorithms {
                self.datas = algorithm.calculateIndex(self.datas)
            }
        }
    }
    
    /// 点击位置所在的分区
    func getSectionByTouchPoint(_ point: CGPoint) -> (Int, BMKLineSection?) {
        for (i, section) in self.sections.enumerated() {
            if section.frame.contains(point) {
                return (i, section)
            }
        }
        return (-1, nil)
    }
    
    /// 显示X轴坐标的分区
    func getSecionWhichShowXAxis() -> BMKLineSection? {
        let visiableSection = self.sections.filter { !$0.isHidden }
        var showSection: BMKLineSection?
        for (i, section) in visiableSection.enumerated() {
            if section.index == self.showXAxisOnSection {
                showSection = section
            }
            if i == visiableSection.count - 1 && showSection == nil {
                showSection = section
            }
        }
        return showSection
    }
    
    func setSelectedIndexByPoint(_ point: CGPoint) {
        guard self.enableTap else {
            return
        }
        if point.equalTo(CGPoint.zero) {
            return
        }
        let (_, section) = self.getSectionByTouchPoint(point)
        if section == nil {
            return
        }
        let visiableSections = self.sections.filter { !$0.isHidden }
        guard let lastSection = visiableSections.last else {
            return
        }
        guard let showXAxisSection = self.getSecionWhichShowXAxis() else {
            return
        }
        
        self.selectedYAxisLabel?.font = self.labelFont
        self.selectedYAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedYAxisLabel?.textColor = self.selectedTextColor
        self.selectedXAxisLabel?.font = self.labelFont
        self.selectedXAxisLabel?.backgroundColor = self.selectedBGColor
        self.selectedXAxisLabel?.textColor = self.selectedTextColor
        
        let yAxis = section!.yAxis
        let format = "%.".appendingFormat("%df", yAxis.decimal)
        
        self.selectedPoint = point
        
        // 两点间隔宽度
        let plotWidth = (section!.frame.size.width - section!.padding.left - section!.padding.right) / CGFloat(self.rangeTo - self.rangeFrom)
        
        // Y轴坐标的实际值
        var yVal: CGFloat = 0
        
        for i in self.rangeFrom...self.rangeTo - 1 {
            let ixs = plotWidth * CGFloat(i - self.rangeFrom) + section!.padding.left + self.padding.left
            let ixe = plotWidth * CGFloat(i - self.rangeFrom + 1) + section!.padding.left + self.padding.left
            if ixs <= point.x && point.x < ixe {
                self.selectedPointIndex = i
                let item = self.datas[i]
                var hX = section!.frame.origin.x + section!.padding.left
                hX = hX + plotWidth * CGFloat(i - self.rangeFrom) + plotWidth / 2
                let hY = self.padding.top
                let hHeight = lastSection.frame.maxY
                self.horizontalLineView?.frame = CGRect(x: hX, y: hY, width: self.lineWidth, height: hHeight)
                
                let vX = section!.frame.origin.x + section!.padding.left
                var vY: CGFloat = 0
                switch self.selectedPosition {
                case .free:
                    vY = point.y
                    yVal = section!.getValue(with: point.y)
                case .onClosePrice:
                    if let series = section?.getSeries(key: BMKLineSeriesKey.candle), !series.hidden {
                        yVal = item.closePrice
                    } else if let series = section?.getSeries(key: BMKLineSeriesKey.timeline), !series.hidden {
                        yVal = item.closePrice
                    } else if let series = section?.getSeries(key: BMKLineSeriesKey.volume), !series.hidden {
                        yVal = item.vol
                    }
                    vY = section!.getY(with: yVal)
                }
                let hWidth = section!.frame.size.width - section!.padding.left - section!.padding.right
                self.verticalLineView?.frame = CGRect(x: vX, y: vY - self.lineWidth / 2, width: hWidth, height: self.lineWidth)
                
                var yAxisStartX: CGFloat = 0
                switch self.yAxisShowPosition {
                case .left:
                    yAxisStartX = section!.frame.origin.x
                case .right:
                    yAxisStartX = section!.frame.maxX - self.yAxisLabelWidth
                case .none:
                    self.selectedYAxisLabel?.isHidden = true
                }
                self.selectedYAxisLabel?.text = String(format: format, yVal)
                self.selectedYAxisLabel?.frame = CGRect(x: yAxisStartX, y: vY - self.labelSize.height / 2, width: self.yAxisLabelWidth, height: self.labelSize.height)
                
                let time = Date.bm_timeStringOfStamp(item.time, format: "yyyy-MM-dd HH:mm")
                let size = time.bm_sizeWithConstrained(self.labelFont)
                self.selectedXAxisLabel?.text = time
                
                // 判断是否超过左右边界
                let labelWidth = size.width  + 6
                var hXTemp = hX - (labelWidth) / 2
                if hXTemp < section!.frame.origin.x {
                    hXTemp = section!.frame.origin.x
                } else if hXTemp + labelWidth > section!.frame.origin.x + section!.frame.size.width {
                    hXTemp = section!.frame.origin.x + section!.frame.size.width - labelWidth
                }
                self.selectedXAxisLabel?.frame = CGRect(x: hXTemp, y: showXAxisSection.frame.maxY, width: size.width  + 6, height: self.labelSize.height)
                
                self.sightView?.center = CGPoint(x: hX, y: vY)
                
                // 允许开发者进行最后的自定义
                self.delegate?.kLineChart?(chart: self, labelOfYAxis: self.selectedXAxisLabel!, labelOfXAxis: self.selectedYAxisLabel!)
                
                self.showSelection = true
                
                self.bringSubviewToFront(self.verticalLineView!)
                self.bringSubviewToFront(self.horizontalLineView!)
                self.bringSubviewToFront(self.selectedXAxisLabel!)
                self.bringSubviewToFront(self.selectedYAxisLabel!)
                self.bringSubviewToFront(self.sightView!)
                
                self.setSelectedPointIndex(i)
                
                break
            }
        }
    }
    
    func setSelectedPointIndex(_ index: Int) {
        guard index >= self.rangeFrom && index < self.rangeTo else {
            return
        }
        self.selectedPointIndex = index
        let item = self.datas[index]
        for (_, section) in self.sections.enumerated() {
            if section.isHidden {
                continue
            }
            if let titleString = self.delegate?.kLineChart?(chart: self, titleForHeaderInSection: section, index: index, item: self.datas[index]) {
                section.drawTitleForHeader(title: titleString) // 用户自定义
            } else {
                section.drawTitle(index) // 默认
            }
        }
        self.delegate?.kLineChart?(chart: self, didSelectAt: index, item: item)
    }
}

// MARK: - 绘图图层
extension BMKLineChartView {
    
    func removeSublayers() {
        for section in self.sections {
            section.removeSublayers()
            for series in section.seriesArray {
                series.removeSublayers()
            }
        }
        _ = self.drawLayer.sublayers?.map { $0.removeFromSuperlayer() }
        self.drawLayer.sublayers?.removeAll()
    }
    
    /// 通过 CALayer 绘制图表
    func drawLayerView() {
        // 先清空图层
        self.removeSublayers()
        // 初始化图表数据结构
        guard self.initChart() else {
            return
        }
        // 待绘制的X坐标标签
        var xAxisToDraw: [(CGRect, String)] = []
        
        // 建立每个分区
        self.buildSections { (section, index) in
            // 分区的小数保留位数
            let decimal = self.delegate?.kLineChart?(chart: self, decimalAt: index) ?? 2
            section.decimal = decimal
            
            // 初始Y轴数据
            self.initYAxis(section)
            
            // 绘制每个区域
            self.drawSection(section)
            
            // 绘制X轴坐标系, 先绘制辅助线, 记录标签位置返回并保存, 等到最后才在需要显示的分区上绘制
            xAxisToDraw = self.drawXAxis(section)
            
            // 绘制Y轴坐标系, 最后的Y轴标签等到绘制完线段才绘制
            let yAxisToDraw = self.drawYAxis(section)
            
            // 绘制图表的系列点线
            self.drawChart(section)
            
            // 绘制Y轴坐标上的标签
            self.drawYAxisLabel(yAxisToDraw)
            
            // 添加标题到主绘图层
            self.drawLayer.addSublayer(section.titleLayer)
            
            // 用户是否自定义标题视图
            if let titleView = self.delegate?.kLineChart?(chart: self, viewForHeaderInSection: index) {
                section.isShowTitle = false
                section.drawCustomTitleForHeader(titleView, inView: self)
            } else {
                if let titleString = self.delegate?.kLineChart?(chart: self, titleForHeaderInSection: section, index: self.selectedPointIndex, item: self.datas[self.selectedPointIndex]) {
                    section.drawTitleForHeader(title: titleString)
                } else {
                    section.drawTitle(self.selectedPointIndex) // 显示范围内最后一个点的数据
                }
            }
        }
        
        if let showXAxisSection = self.getSecionWhichShowXAxis() {
            self.drawXAxisLabel(showXAxisSection, xAxisToDraw: xAxisToDraw)
        }
        
        self.delegate?.didFinishKLineChartRefresh?(chart: self)
    }
    
    /// 初始化图表数据结构
    fileprivate func initChart() -> Bool {
        self.plotCount = self.delegate?.numberOfPointsInKLineChart(chart: self) ?? 0
        
        if self.plotCount != self.datas.count { // 数据不一致, 重新计算
            self.resetData()
        }
        
        if plotCount > 0 {
            if self.isShowPlotAll { // 显示全部数据
                self.range = self.plotCount
                self.rangeFrom = 0
                self.rangeTo = self.plotCount
            }
            
            if self.scrollToPosition == .none {
                if self.rangeTo == 0 || self.plotCount < self.rangeTo {
                    self.scrollToPosition = .tail
                }
            }
            
            if self.scrollToPosition == .head {
                self.rangeFrom = 0
                if self.rangeFrom + self.range < self.plotCount {
                    self.rangeTo = self.rangeFrom + self.range
                } else {
                    self.rangeTo = self.plotCount
                }
                self.selectedPointIndex = -1
            } else if self.scrollToPosition == .tail {
                self.rangeTo = self.plotCount
                if self.rangeTo - self.range > 0 {
                    self.rangeFrom = self.rangeTo - range
                } else {
                    self.rangeFrom = 0
                }
                self.selectedPointIndex = -1
            }
        }
        
        self.scrollToPosition = .none // 刷新图表, 默认不处理滚动
        
        if self.selectedPointIndex < 0 || self.selectedPointIndex >= self.rangeTo {
            self.selectedPointIndex = self.rangeTo - 1
        }
        
        let backgroundLayer = BMKLineShapeLayer()
        let backgroundPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height), cornerRadius: 0)
        backgroundLayer.path = backgroundPath.cgPath
        backgroundLayer.fillColor = self.backgroundColor?.cgColor
        self.drawLayer.addSublayer(backgroundLayer)
        
        return self.datas.count > 0 ? true : false
    }
    
    /// 初始化各个分区
    ///
    /// - Parameter complete: 初始化分区后, 绘制每个分区
    fileprivate func buildSections(_ complete:(_ section: BMKLineSection, _ index: Int) -> Void) {
        var height = self.frame.size.height - (self.padding.top + self.padding.bottom)
        let xAxisHeight = self.delegate?.heightForXAxisInKLineChart?(in: self) ?? self.DefaultXAxisHegiht
        height = height - xAxisHeight
        
        let width = self.frame.size.width - (self.padding.left + self.padding.right)
        
        var total = 0
        for (index, section) in self.sections.enumerated() {
            section.index = index
            if !section.isHidden {
                if section.ratios > 0 {
                    total = total + section.ratios
                }
            }
        }
        
        var offsetY: CGFloat = self.padding.top
        for (index, section) in self.sections.enumerated() { // 计算每个区域的高度，并绘制
            var heightOfSection: CGFloat = 0
            let widthOfSection = width
            if section.isHidden {
                continue
            }
            if section.fixedHeight > 0 {
                heightOfSection = section.fixedHeight
                height = height - heightOfSection
            } else {
                heightOfSection = height * CGFloat(section.ratios) / CGFloat(total)
            }
            
            self.yAxisLabelWidth = self.delegate?.widthForYAxisLabelInKLineChart?(in: self) ?? self.DefaultYAxisLabelWidth
            switch self.yAxisShowPosition {
            case .left:
                section.padding.left = self.isInnerYAxis ? section.padding.left : self.yAxisLabelWidth
                section.padding.right = 0
            case .right:
                section.padding.left = 0
                section.padding.right = self.isInnerYAxis ? section.padding.right : self.yAxisLabelWidth
            case .none:
                section.padding.left = 0
                section.padding.right = 0
            }
            
            section.frame = CGRect(x: 0 + self.padding.left, y: offsetY, width: widthOfSection, height: heightOfSection)
            
            offsetY = offsetY + section.frame.height
            
            if self.showXAxisOnSection == index {
                offsetY = offsetY + xAxisHeight
            }
            
            complete(section, index)
        }
    }
    
    /// 准备绘制X轴上的标签
    fileprivate func drawXAxis(_ section: BMKLineSection) -> [(CGRect, String)] {
        var xAxisToDraw = [(CGRect, String)]()
        
        let xAxis = BMKLineShapeLayer()
        
        var startX: CGFloat = section.frame.origin.x + section.padding.left
        let endX: CGFloat = section.frame.origin.x + section.frame.size.width - section.padding.right
        let secWidth: CGFloat = section.frame.size.width
        let secPaddingLeft: CGFloat = section.padding.left
        let secPaddingRight: CGFloat = section.padding.right
        
        let dataRange = self.rangeTo - self.rangeFrom
        var xTickInterval: Int = dataRange / self.xAxisPerInterval
        if xTickInterval <= 0 {
            xTickInterval = 1
        }
        
        let perPlotWidth: CGFloat = (secWidth - secPaddingLeft - secPaddingRight) / CGFloat(self.rangeTo - self.rangeFrom)
        let startY = section.frame.maxY
        var k: Int = 0
        var showXAxisReference = false
        
        for i in stride(from: self.rangeFrom, to: self.rangeTo, by: xTickInterval) { // for var i = self.rangeFrom; i < self.rangeTo; i = i + xTickInterval
            let xLabel = self.delegate?.kLineChart?(chart: self, labelOnXAxisForIndex: i) ?? ""
            var textSize = xLabel.bm_sizeWithConstrained(self.labelFont)
            textSize.width = textSize.width + 4
            var xPox = startX - textSize.width / 2 + perPlotWidth / 2
            if xPox < 0 {
                xPox = startX
            } else if (xPox + textSize.width > endX) {
                xPox = endX - textSize.width
            }
            let barLabelRect = CGRect(x: xPox, y: startY, width: textSize.width, height: textSize.height)
            xAxisToDraw.append((barLabelRect, xLabel))
            
            // 绘制辅助线
            let referencePath = UIBezierPath()
            let referenceLayer = BMKLineShapeLayer()
            referenceLayer.lineWidth = self.lineWidth
            switch section.xAxis.referenceStyle {
            case let .dash(color: dashColor, pattern: pattern):
                referenceLayer.strokeColor = dashColor.cgColor
                referenceLayer.lineDashPattern = pattern
                showXAxisReference = true
            case let .solid(color: solidColor):
                referenceLayer.strokeColor = solidColor.cgColor
                showXAxisReference = true
            default:
                showXAxisReference = false
            }
            if showXAxisReference {
                referencePath.move(to: CGPoint(x: xPox + textSize.width / 2, y: section.frame.minY))
                referencePath.addLine(to: CGPoint(x: xPox + textSize.width / 2, y: section.frame.maxY))
                referenceLayer.path = referencePath.cgPath
                xAxis.addSublayer(referenceLayer)
            }

            k = k + xTickInterval
            startX = perPlotWidth * CGFloat(k)
        }
        
        self.drawLayer.addSublayer(xAxis)
        
        return xAxisToDraw
    }
    
    /// 绘制X轴上的标签
    ///
    /// - Parameters:
    ///   - section: 绘制在那个分区
    ///   - xAxisToDraw: 待绘制内容
    fileprivate func drawXAxisLabel(_ section: BMKLineSection, xAxisToDraw: [(CGRect, String)]) {
        guard self.isShowXAxisLabel else {
            return
        }
        guard xAxisToDraw.count > 0 else {
            return
        }
        let startY = section.frame.maxY
        let xAxis = BMKLineShapeLayer()
        for (var barLabelRect, xLabel) in xAxisToDraw {
            barLabelRect.origin.y = startY
            let xLabelText = BMKLineTextLayer()
            xLabelText.frame = barLabelRect
            xLabelText.string = xLabel
            xLabelText.alignmentMode = CATextLayerAlignmentMode.center
            xLabelText.fontSize = self.labelFont.pointSize
            xLabelText.foregroundColor =  self.textColor.cgColor
            xLabelText.backgroundColor = UIColor.clear.cgColor
            xLabelText.contentsScale = UIScreen.main.scale
            xAxis.addSublayer(xLabelText)
        }
        self.drawLayer.addSublayer(xAxis)
    }
    
    /// 绘制分区
    fileprivate func drawSection(_ section: BMKLineSection) {
        // 分区背景
        let sectionPath = UIBezierPath(rect: section.frame)
        let sectionLayer = BMKLineShapeLayer()
        sectionLayer.fillColor = section.backgroundColor.cgColor
        sectionLayer.path = sectionPath.cgPath
        self.drawLayer.addSublayer(sectionLayer)
        
        let borderPath = UIBezierPath()
        if self.borderWidth.bottom > 0 {
            borderPath.append(UIBezierPath(rect: CGRect(x: section.frame.origin.x + section.padding.left,
                                                        y: section.frame.size.height + section.frame.origin.y,
                                                        width: section.frame.size.width - section.padding.left,
                                                        height: self.borderWidth.bottom)))
        }
        if self.borderWidth.top > 0 {
            borderPath.append(UIBezierPath(rect: CGRect(x: section.frame.origin.x + section.padding.left,
                                                        y: section.frame.origin.y,
                                                        width: section.frame.size.width - section.padding.left,
                                                        height: self.borderWidth.top)))
        }
        if self.borderWidth.left > 0 {
            borderPath.append(UIBezierPath(rect: CGRect(x: section.frame.origin.x + section.padding.left,
                                                        y: section.frame.origin.y,
                                                        width: self.borderWidth.left,
                                                        height: section.frame.size.height)))
        }
        if self.borderWidth.right > 0 {
            borderPath.append(UIBezierPath(rect: CGRect(x: section.frame.origin.x + section.frame.size.width - section.padding.right,
                                                        y: section.frame.origin.y,
                                                        width: self.borderWidth.left,
                                                        height: section.frame.size.height)))
        }
        let borderLayer = BMKLineShapeLayer()
        borderLayer.path = borderPath.cgPath
        borderLayer.lineWidth = self.lineWidth
        borderLayer.fillColor = self.lineColor.cgColor
        self.drawLayer.addSublayer(borderLayer)
    }
    
    /// 初始化分区上各个线的Y轴
    fileprivate func initYAxis(_ section: BMKLineSection) {
        if section.seriesArray.count > 0 {
            section.buildYAxis(startIndex: self.rangeFrom, endIndex: self.rangeTo, datas: self.datas)
        }
    }
    
    /// 准备绘制Y轴坐标
    fileprivate func drawYAxis(_ section: BMKLineSection) -> [(CGRect, String)] {
        var yAxisToDraw = [(CGRect, String)]()
        var valueToDraw = Set<CGFloat>()
        
        var startX: CGFloat = 0, startY: CGFloat = 0, extrude: CGFloat = 0
        var showYAxisLabel: Bool = true
        var showYAxisReference: Bool = true
        
        switch self.yAxisShowPosition {
        case .left:
            startX = section.frame.origin.x - 3 * (self.isInnerYAxis ? -1 : 1)
            extrude = section.frame.origin.x + section.padding.left - 2
        case .right:
            startX = section.frame.maxX - self.yAxisLabelWidth + 3 * (self.isInnerYAxis ? -1 : 1)
            extrude = section.frame.origin.x + section.padding.left + section.frame.size.width - section.padding.right
        case .none:
            showYAxisLabel = false
        }
        
        let yaxis = section.yAxis
        
        // 计算Y轴的标签及虚线分几段
        let step = (yaxis.max - yaxis.min) / CGFloat(yaxis.tickInterval)
        
        var i = 0
        var yVal = yaxis.baseValue + CGFloat(i) * step
        while yVal <= yaxis.max && i <= yaxis.tickInterval {
            valueToDraw.insert(yVal)
            i = i + 1
            yVal = yaxis.baseValue + CGFloat(i) * step
        }
        
        i = 0
        yVal = yaxis.baseValue - CGFloat(i) * step
        while yVal >= yaxis.min && i <= yaxis.tickInterval {
            valueToDraw.insert(yVal)
            i =  i + 1
            yVal = yaxis.baseValue - CGFloat(i) * step
        }
        
        for (i, yVal) in valueToDraw.enumerated() { // 绘制虚线和Y标签值
            let iy = section.getY(with: yVal)
            
            if self.isInnerYAxis { // 为了不挡住辅助线, 向上移动Y轴的数值位置
                startY = iy - 14
            } else {
                startY = iy - 7
            }
            
            let referencePath = UIBezierPath()
            let referenceLayer = BMKLineShapeLayer()
            referenceLayer.lineWidth = self.lineWidth
            
            if section.type == .master {
                switch section.yAxis.referenceStyle {
                case let .dash(color: dashColor, pattern: pattern):
                    referenceLayer.strokeColor = dashColor.cgColor
                    referenceLayer.lineDashPattern = pattern
                    showYAxisReference = true
                case let .solid(color: solidColor):
                    referenceLayer.strokeColor = solidColor.cgColor
                    showYAxisReference = true
                default:
                    showYAxisReference = false
                    startY = iy - 7
                }
            } else {
                showYAxisReference = false
                startY = iy - 7
            }

            if showYAxisReference {
                if !self.isInnerYAxis {
                    referencePath.move(to: CGPoint(x: extrude, y: iy))
                    referencePath.addLine(to: CGPoint(x: extrude + 2, y: iy))
                }
                referencePath.move(to: CGPoint(x: section.frame.origin.x + section.padding.left, y: iy))
                referencePath.addLine(to: CGPoint(x: section.frame.origin.x + section.frame.size.width - section.padding.right, y: iy))
                referenceLayer.path = referencePath.cgPath
                self.drawLayer.addSublayer(referenceLayer)
            }
            
            if showYAxisLabel {
                let strValue = self.delegate?.kLineChart(chart: self, labelOnYAxisForValue: yVal, atIndex: i, section: section) ?? ""
                let yLabelRect = CGRect(x: startX, y: startY, width: yAxisLabelWidth, height: 12
                )
                yAxisToDraw.append((yLabelRect, strValue))
            }
        }
        
        return yAxisToDraw
    }
    
    /// 绘制Y轴坐标上的标签
    fileprivate func drawYAxisLabel(_ yAxisToDraw: [(CGRect, String)]) {
        var alignmentMode = CATextLayerAlignmentMode.left
        switch self.yAxisShowPosition {
        case .left:
            alignmentMode = self.isInnerYAxis ? CATextLayerAlignmentMode.left : CATextLayerAlignmentMode.right
        case .right:
            alignmentMode = self.isInnerYAxis ? CATextLayerAlignmentMode.right : CATextLayerAlignmentMode.left
        case .none:
            alignmentMode = CATextLayerAlignmentMode.left
        }
        for (yLabelRect, strValue) in yAxisToDraw {
            let yAxisLabel = BMKLineTextLayer()
            yAxisLabel.frame = yLabelRect
            yAxisLabel.string = strValue
            yAxisLabel.fontSize = self.labelFont.pointSize
            yAxisLabel.foregroundColor =  self.textColor.cgColor
            yAxisLabel.backgroundColor = UIColor.clear.cgColor
            yAxisLabel.alignmentMode = alignmentMode
            yAxisLabel.contentsScale = UIScreen.main.scale
            self.drawLayer.addSublayer(yAxisLabel)
        }
    }
    
    /// 绘制分区的系列点线
    func drawChart(_ section: BMKLineSection) {
        if section.isPageable { // 如果分区以分页显示, 绘制当前系列
            let series = section.seriesArray[section.selectedIndex]
            let seriesLayer = self.drawSeries(series)
            section.sectionLayer.addSublayer(seriesLayer)
        } else { // 不分页显示, 绘制全部系列
            for serie in section.seriesArray {
                let seriesLayer = self.drawSeries(serie)
                section.sectionLayer.addSublayer(seriesLayer)
            }
        }
        self.drawLayer.addSublayer(section.sectionLayer)
    }
    
    /// 绘制分区上的系列点线
    func drawSeries(_ serie: BMKLineSeries) -> BMKLineShapeLayer {
        if !serie.hidden {
            for model in serie.chartModels {
                let serieLayer = model.drawSerie(seriesKey: serie.key, self.rangeFrom, endIndex: self.rangeTo)
                serie.seriesLayer.addSublayer(serieLayer)
            }
        }
        return serie.seriesLayer
    }
}

// MARK: - Public Methods
extension BMKLineChartView {
    
    /// 刷新图表
    public func reloadData(toPosition: BMKLineChartViewScrollPosition = .none, resetData: Bool = true) {
        self.scrollToPosition = toPosition
        if resetData {
            self.resetData()
        }
        self.drawLayerView()
    }
    
    /// 刷新图表风格
    public func resetStyle(style: BMKLineChartStyle) {
        self.style = style
        self.showSelection = false
        self.reloadData()
    }
    
    /// 通过主键隐藏或显示分区
    public func setSection(hidden: Bool, byKey key: String) {
        for section in self.sections {
            if section.key == key && section.type == .assistant { // 副图才能隐藏
                section.isHidden = hidden
                break
            }
        }
    }
    
    /// 通过索引隐藏或显示分区
    public func setSection(hidden: Bool, byIndex index: Int) {
        guard let section = self.sections[safe: index], section.type == .assistant else { // 副图才能隐藏
            return
        }
        section.isHidden = hidden
    }
    
    /// 通过主键隐藏或显示线系列
    ///
    /// - Parameters:
    ///   - key: key == "" 时显示或隐藏分区全部线系列
    ///   - inSection: inSection == -1时, 显示或隐藏全部分区
    public func setSerie(hidden: Bool, by key: String = "", inSection: Int = -1) {
        var hideSections = [BMKLineSection]()
        if inSection < 0 {
            hideSections = self.sections
        } else {
            if inSection >= self.sections.count {
                return
            }
            hideSections.append(self.sections[inSection])
        }
        for section in hideSections {
            for (index, serie) in section.seriesArray.enumerated() {
                if key == "" {
                    if section.isPageable {
                        section.selectedIndex = 0
                    } else {
                        serie.hidden = hidden
                    }
                } else if serie.key == key {
                    if section.isPageable {
                        if hidden == false {
                            section.selectedIndex = index
                        }
                    } else {
                        serie.hidden = hidden
                    }
                    break
                }
            }
        }
    }
    
    /// 缩放图表
    public func zoomChart(by interval: Int, enlarge: Bool) {
        var newRangeTo = 0
        var newRangeFrom = 0
        var newRange = 0
        
        if enlarge {
            newRangeTo = self.rangeTo - interval
            newRangeFrom = self.rangeFrom + interval
            newRange = self.rangeTo - self.rangeFrom
            if newRange >= MinRange {
                if self.plotCount > self.rangeTo - self.rangeFrom {
                    if newRangeFrom < self.rangeTo {
                        self.rangeFrom = newRangeFrom
                    }
                    if newRangeTo > self.rangeFrom {
                        self.rangeTo = newRangeTo
                    }
                } else {
                    if newRangeTo > self.rangeFrom {
                        self.rangeTo = newRangeTo
                    }
                }
                self.range = self.rangeTo - self.rangeFrom
                self.drawLayerView()
            }
        } else {
            newRangeTo = self.rangeTo + interval
            newRangeFrom = self.rangeFrom - interval
            newRange = self.rangeTo - self.rangeFrom
            if newRange <= MaxRange {
                if newRangeFrom >= 0 {
                    self.rangeFrom = newRangeFrom
                } else {
                    self.rangeFrom = 0
                    newRangeTo = newRangeTo - newRangeFrom
                }
                if newRangeTo <= self.plotCount {
                    self.rangeTo = newRangeTo
                } else {
                    self.rangeTo = self.plotCount
                    newRangeFrom = newRangeFrom - (newRangeTo - self.plotCount)
                    if newRangeFrom < 0 {
                        self.rangeFrom = 0
                    } else {
                        self.rangeFrom = newRangeFrom
                    }
                }
                self.range = self.rangeTo - self.rangeFrom
                self.drawLayerView()
            }
        }
    }
    
    /// 平移图表
    public func moveChart(by interval: Int, direction: Bool) {
        if (interval > 0) {
            if direction { // 向右拖往后查看数据
                if self.plotCount > (self.rangeTo-self.rangeFrom) {
                    if self.rangeFrom - interval >= 0 {
                        self.rangeFrom -= interval
                        self.rangeTo -= interval
                    } else {
                        self.rangeFrom = 0
                        self.rangeTo -= self.rangeFrom
                    }
                    self.drawLayerView()
                }
            } else { // 向左拖往前查看数据
                if self.plotCount > (self.rangeTo-self.rangeFrom) {
                    if self.rangeTo + interval <= self.plotCount {
                        self.rangeFrom += interval
                        self.rangeTo += interval
                    } else {
                        self.rangeFrom += self.plotCount - self.rangeTo
                        self.rangeTo  = self.plotCount
                    }
                    self.drawLayerView()
                }
            }
        }
        self.range = self.rangeTo - self.rangeFrom
    }
    
    /// 生成图表截图
    open var image: UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return capturedImage!
    }
    
    /// 自定义分区头部标题显示内容
    ///
    /// - Parameters:
    ///   - titles: 元组(文本, 颜色)
    ///   - section: 分区位置
    open func setHeader(titlesAndAttrs: [(title: String, color: UIColor)], inSection section: Int)  {
        guard let section = self.sections[safe: section] else {
            return
        }
        section.prepareDrawTitle(titlesAndAttributes: titlesAndAttrs)
    }
    
    /// 添加新线系列到分区
    ///
    /// - Parameters:
    ///   - series: 线系列
    ///   - section: 分区位置
    open func addSeries(_ series: BMKLineSeries, inSection section: Int) {
        guard let section = self.sections[safe: section] else {
            return
        }
        section.seriesArray.append(series)
        self.drawLayerView()
    }
    
    /// 通过键名删除分区中的线系列
    ///
    /// - Parameters:
    ///   - key: 主键
    ///   - section: 分区位置
    open func removeSeries(key: String, inSection section: Int) {
        guard let section = self.sections[safe: section] else {
            return
        }
        section.removeSeries(key: key)
        self.drawLayerView()
    }
}

// MARK: - 手势
extension BMKLineChartView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        switch gestureRecognizer {
        case is UITapGestureRecognizer:
            return self.enableTap
        case is UIPanGestureRecognizer:
            return self.enablePan
        case is UIPinchGestureRecognizer:
            return self.enablePinch
        default:
            return false
        }
    }
   
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer {
            let pan = gestureRecognizer as! UIPanGestureRecognizer
            let translation = pan.translation(in: self)
            if abs(translation.y) > abs(translation.x * 5) {
                // 垂直滑动, 传递手势, 禁止 K 线图滑动
                self.panShouldMoveChart = false
                return true
            } else {
                // 水平滑动, 不传递手势, 允许 K 线图滑动
                self.panShouldMoveChart = true
                return false
            }
        }
        return false
    }
    
    @objc func doTapAction(_ sender: UITapGestureRecognizer) {
        guard self.enableTap else {
            return
        }
        let point = sender.location(in: self)
        let (_, section) = self.getSectionByTouchPoint(point)
        if let section = section {
            if section.isPageable {
                section.nextPageSeries()
                self.drawLayerView()
                self.delegate?.kLineChart?(
                    chart: self,
                    didFlipPageSeries: section,
                    series: section.seriesArray[section.selectedIndex],
                    seriesIndex: section.selectedIndex
                )
            } else {
                self.setSelectedIndexByPoint(point)
            }
        }
    }
    
    @objc func doPanAction(_ sender: UIPanGestureRecognizer) {
        guard self.enablePan else {
            return
        }
        guard self.panShouldMoveChart else {
            return
        }
        
        self.showSelection = false
        
        let visiableSection = self.sections.filter { !$0.isHidden }
        guard let section = visiableSection.first else {
            return
        }
        
        let location = sender.location(in: self)
        let translation = sender.translation(in: self)
        let velocity = sender.velocity(in: self)
        let plotWidth = (section.frame.size.width - section.padding.left - section.padding.right) / CGFloat(self.rangeTo - self.rangeFrom)
        
        switch sender.state {
        case .began:
            self.dynamicAnimator.removeAllBehaviors()
        case .changed:
            let distance = abs(translation.x)
            if distance > plotWidth {
                let isRight = translation.x > 0 ? true : false
                let interval = lroundf(abs(Float(distance / plotWidth)))
                self.moveChart(by: interval, direction: isRight)
                sender.setTranslation(CGPoint(x: 0, y: 0), in: self)
            }
        case .ended, .cancelled:
            self.decelerationStartX = 0
            self.dynamicItem.center = self.bounds.origin
            let decelerationBehavior = UIDynamicItemBehavior(items: [self.dynamicItem])
            decelerationBehavior.addLinearVelocity(velocity, for: self.dynamicItem)
            decelerationBehavior.resistance = 2.0
            decelerationBehavior.action = { [weak self]() -> Void in
                if self?.rangeFrom == 0 || self?.rangeTo == self?.plotCount {
                    return
                }
                let itemX = self?.dynamicItem.center.x ?? 0
                let startX = self?.decelerationStartX ?? 0
                let distance = abs(itemX - startX)
                if distance > plotWidth {
                    let isRight = itemX > 0 ? true : false
                    let interval = lroundf(abs(Float(distance / plotWidth)))
                    self?.moveChart(by: interval, direction: isRight)
                    self?.decelerationStartX = itemX
                }
            }
            self.dynamicAnimator.addBehavior(decelerationBehavior)
            self.decelerationBehavior = decelerationBehavior
        default:
            break
        }
    }
    
    @objc func doPinchAction(_ sender: UIPinchGestureRecognizer) {
        guard self.enablePinch else {
            return
        }
        
        self.showSelection = false
        
        let visiableSection = self.sections.filter { !$0.isHidden }
        guard let section = visiableSection.first else {
            return
        }
        
        let plotWidth = (section.frame.size.width - section.padding.left - section.padding.right) / CGFloat(self.rangeTo - self.rangeFrom)
        let scale = sender.scale
        let newPlotWidth = plotWidth * scale
        let newRangeTemp = (section.frame.size.width - section.padding.left - section.padding.right) / newPlotWidth
        let newRange = scale > 1 ? Int(newRangeTemp + 1) : Int(newRangeTemp)
        let distance = abs(self.range - newRange)
        if distance % 2 == 0 && distance > 0 {
            let enlarge = scale > 1 ? true : false
            self.zoomChart(by: distance / 2, enlarge: enlarge)
            sender.scale = 1
        }
    }
}
