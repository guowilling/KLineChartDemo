
import UIKit
//import CHKLineChartKit

class ChartCustomViewController: UIViewController {
    
    /// 不显示
    static let Hide: String = ""
    
    /// 时间周期
    let times: [String] = ["5min", "15min", "1hour", "6hour", "1day"]
    
    /// 主图线段
    let masterLines: [String] = [CHSeriesKey.candle, CHSeriesKey.timeline]
    
    /// 主图指标
    let masterIndexes: [String] = [CHSeriesKey.ma, CHSeriesKey.ema, CHSeriesKey.sar, CHSeriesKey.boll, CHSeriesKey.sam, Hide]
    
    /// 副图指标
    let assistIndexes: [String] = [CHSeriesKey.volume, CHSeriesKey.sam, CHSeriesKey.kdj, CHSeriesKey.macd, CHSeriesKey.rsi, Hide]
    
    /// 选择交易对
    let exPairs: [String] = ["BTC-USD", "ETH-USD", "LTC-USD", "LTC-BTC", "ETH-BTC", "BCH-BTC"]
    
    /// 已选周期
    var selectedTime: Int = 0 {
        didSet {
            let time = self.times[self.selectedTime]
            self.buttonTime.setTitle(time, for: .normal)
        }
    }
    
    /// 已选交易对
    var selectedExPair: Int = 0
    
    /// 蜡烛柱颜色
    var selectedCandleColor: Int = 1
    
    /// 选择的风格
    var selectedTheme: Int = 0
    
    /// Y 轴显示方向
    var selectedYAxisSide: Int = 1
    
    /// 已选主图线段
    var selectedMasterLine: Int = 0
    
    /// 已选主图指标
    var selectedMasterIndex: Int = 0
    
    /// 已选副图指标1
    var selectedAssistIndex1: Int = 0
    
    /// 已选副图指标2
    var selectedAssistIndex2: Int = 0
    
    /// 数据源
    var chartPoints = [KLineChartPoint]()
    
    /// X 轴的前一天, 用于对比是否夸日
    var chartXAxisPrevDay: String = ""
    
    lazy var chartView: CHKLineChartView = {
        let view = CHKLineChartView(frame: CGRect.zero)
        view.style = self.loadUserStyle()
        view.delegate = self
        return view
    }()
    
    lazy var topView: ChartCustomTopView = {
        let view = ChartCustomTopView(frame: CGRect.zero)
        return view
    }()
    
    lazy var buttonTime: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor(hex: 0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.buttonTimeAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var buttonIndex: UIButton = {
        let btn = UIButton()
        btn.setTitle("Index", for: .normal)
        btn.setTitleColor(UIColor(hex: 0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.buttonIndexAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var buttonIndexParams: UIButton = {
        let btn = UIButton()
        btn.setTitle("Params", for: .normal)
        btn.setTitleColor(UIColor(hex: 0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.buttonIndexParamsAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var buttonStyle: UIButton = {
        let btn = UIButton()
        btn.setTitle("Style", for: .normal)
        btn.setTitleColor(UIColor(hex: 0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.buttonStyleAction), for: .touchUpInside)
        return btn
    }()
    
    lazy var buttonExPairs: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 40))
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor(hex: 0xfe9d25), for: .normal)
        btn.addTarget(self, action: #selector(self.buttonExPairsAction(_:)), for: .touchUpInside)
        return btn
    }()
    
    lazy var bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: 0x242731)
        return view
    }()
    
    lazy var selectionPopVCForTimes: SelectionPopViewController = {
        let vc = SelectionPopViewController() { (vc, indexPath) in
            self.selectedTime = indexPath.row
            self.fetchKLineChartData()
        }
        return vc
    }()
    
    lazy var selectionPopVCForIndex: SelectionPopViewController = {
        let vc = SelectionPopViewController() { (vc, indexPath) in
            switch indexPath.section {
            case 0:
                self.selectedMasterLine = indexPath.row
            case 1:
                self.selectedMasterIndex = indexPath.row
            case 2:
                self.selectedAssistIndex1 = indexPath.row
            case 3:
                self.selectedAssistIndex2 = indexPath.row
            default:
                break
            }
            self.handleChartIndexChanged()
        }
        return vc
    }()
    
    lazy var selectionPopVCForExPairs: SelectionPopViewController = {
        let vc = SelectionPopViewController() { (vc, indexPath) in
            let symbol = self.exPairs[indexPath.row]
            self.selectedExPair = indexPath.row
            self.buttonExPairs.setTitle(symbol, for: .normal)
            self.fetchKLineChartData()
        }
        return vc
    }()
    
    lazy var indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .white)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self.buttonExPairs.setTitle(self.exPairs[self.selectedExPair], for: .normal)
        self.selectedExPair = 0
        self.selectedTime = 0
        self.selectedMasterLine = 0
        self.selectedMasterIndex = 0
        self.selectedAssistIndex1 = 0
        self.selectedAssistIndex2 = 2
        
        self.handleChartIndexChanged()
        
        self.fetchKLineChartData()
    }
    
    func setupUI() {
        self.view.backgroundColor = UIColor(hex: 0x232732)
        
        self.navigationItem.titleView = self.buttonExPairs
        
        self.view.addSubview(self.topView)
        self.view.addSubview(self.chartView)
        self.view.addSubview(self.bottomBar)
        self.view.addSubview(self.indicatorView)
        
        self.bottomBar.addSubview(self.buttonTime)
        self.bottomBar.addSubview(self.buttonIndex)
        self.bottomBar.addSubview(self.buttonIndexParams)
        self.bottomBar.addSubview(self.buttonStyle)
        
        self.topView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.snp.top).offset(5)
            make.left.right.equalToSuperview().inset(10)
            make.height.equalTo(75)
        }
        
        self.chartView.snp.makeConstraints { (make) in
            make.top.equalTo(self.topView.snp.bottom).offset(5)
            make.left.right.equalToSuperview()
            make.height.equalTo(450)
        }
        
        self.bottomBar.snp.makeConstraints { (make) in
            make.top.equalTo(self.chartView.snp.bottom).offset(5)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
//            make.bottom.equalTo(self.view.snp.bottom)
        }
        
        self.buttonTime.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(self.buttonIndex)
            make.height.equalToSuperview()
        }
        self.buttonIndex.snp.makeConstraints { (make) in
            make.left.equalTo(self.buttonTime.snp.right)
            make.width.equalTo(self.buttonIndexParams)
            make.height.equalToSuperview()
        }
        self.buttonIndexParams.snp.makeConstraints { (make) in
            make.left.equalTo(self.buttonIndex.snp.right)
            make.width.equalTo(self.buttonStyle)
            make.height.equalToSuperview()
        }
        self.buttonStyle.snp.makeConstraints { (make) in
            make.left.equalTo(self.buttonIndexParams.snp.right)
            make.right.equalToSuperview()
            make.width.equalTo(self.buttonTime)
            make.height.equalToSuperview()
        }
        
        self.indicatorView.snp.makeConstraints { (make) in
            make.center.equalTo(self.chartView)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func fetchKLineChartData() {
        self.indicatorView.startAnimating()
        self.indicatorView.isHidden = false
        let symbol = self.exPairs[self.selectedExPair]
        KLineChartDataFetcher.shared.getKLineChartData(exPair: symbol, timeType: self.times[self.selectedTime]) { [weak self] (success, chartPoints) in
            self?.indicatorView.stopAnimating()
            self?.indicatorView.isHidden = true
            if success && chartPoints.count > 0 {
                self?.chartPoints = chartPoints
                self?.chartView.reloadData()
                self?.topView.update(data: chartPoints.last!)
            }
        }
    }
    
    func handleChartIndexChanged() {
        let lineKey = self.masterLines[self.selectedMasterLine]
        let masterKey = self.masterIndexes[self.selectedMasterIndex]
        let assist1Key = self.assistIndexes[self.selectedAssistIndex1]
        let assist2Key = self.assistIndexes[self.selectedAssistIndex2]
        
        self.chartView.setSection(hidden: assist1Key == ChartCustomViewController.Hide, byIndex: 1)
        self.chartView.setSection(hidden: assist2Key == ChartCustomViewController.Hide, byIndex: 2)
        
        // 先隐藏所有的线段
        self.chartView.setSerie(hidden: true, inSection: 0)
        self.chartView.setSerie(hidden: true, inSection: 1)
        self.chartView.setSerie(hidden: true, inSection: 2)
        
        // 再显示选中的线段
        self.chartView.setSerie(hidden: false, by: lineKey, inSection: 0)
        if masterKey != ChartCustomViewController.Hide {
            self.chartView.setSerie(hidden: false, by: masterKey, inSection: 0)
        }
        self.chartView.setSerie(hidden: false, by: assist1Key, inSection: 1)
        self.chartView.setSerie(hidden: false, by: assist2Key, inSection: 2)
        
        self.chartView.reloadData(resetData: false)
    }
}

extension ChartCustomViewController {
    
    @IBAction func buttonExPairsAction(_ sender: UIButton) {
        let vc = self.selectionPopVCForExPairs
        vc.clear()
        vc.addItems(section: "ExPairs", items: self.exPairs, selectedIndex: self.selectedExPair)
        vc.show(from: self)
    }
    
    @objc func buttonTimeAction() {
        let vc = self.selectionPopVCForTimes
        vc.clear()
        vc.addItems(section: "Time", items: self.times, selectedIndex: self.selectedTime)
        vc.show(from: self)
    }
    
    @objc func buttonIndexAction() {
        let vc = self.selectionPopVCForIndex
        vc.clear()
        vc.addItems(section: "Chart Line", items: self.masterLines, selectedIndex: self.selectedMasterLine)
        vc.addItems(section: "Master Index", items: self.masterIndexes, selectedIndex: self.selectedMasterIndex)
        vc.addItems(section: "Assist Index 1", items: self.assistIndexes, selectedIndex: self.selectedAssistIndex1)
        vc.addItems(section: "Assist Index 2", items: self.assistIndexes, selectedIndex: self.selectedAssistIndex2)
        vc.show(from: self)
    }
    
    @objc func buttonIndexParamsAction() {
        let vc = SeriesSettingListViewController()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func buttonStyleAction() {
        let vc = ChartStyleSettingViewController()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ChartCustomViewController: CHKLineChartDelegate {
    
    func numberOfPointsInKLineChart(chart: CHKLineChartView) -> Int {
        return self.chartPoints.count
    }
    
    func kLineChart(chart: CHKLineChartView, valueForPointAtIndex index: Int) -> CHChartItem {
        let point = self.chartPoints[index]
        let item = CHChartItem()
        item.time = point.time
        item.openPrice = CGFloat(point.openPrice)
        item.highPrice = CGFloat(point.highPrice)
        item.lowPrice = CGFloat(point.lowPrice)
        item.closePrice = CGFloat(point.closePrice)
        item.vol = CGFloat(point.vol)
        return item
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: CHSection) -> String {
        var lable = ""
        if section.key == "volume" {
            if value / 1000 > 1 {
                lable = (value / 1000).ch_toString(maxF: section.decimal) + "K"
            } else {
                lable = value.ch_toString(maxF: section.decimal)
            }
        } else {
            lable = value.ch_toString(maxF: section.decimal)
        }
        return lable
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        let timestamp = self.chartPoints[index].time
        let dayText = Date.ch_getTimeByStamp(timestamp, format: "MM-dd")
        let timeText = Date.ch_getTimeByStamp(timestamp, format: "HH:mm")
        var lable = ""
        if dayText != self.chartXAxisPrevDay && index > 0 {
            lable = dayText
        } else {
            lable = timeText
        }
        self.chartXAxisPrevDay = dayText
        return lable
    }
    
    func kLineChart(chart: CHKLineChartView, decimalAt section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return 2
        }
    }
    
    func widthForYAxisLabelInKLineChart(in chart: CHKLineChartView) -> CGFloat {
        return 60
    }
    
    func kLineChart(chart: CHKLineChartView, titleForHeaderInSection section: CHSection, index: Int, item: CHChartItem) -> NSAttributedString? {
        let titleString = NSMutableAttributedString()
        var key = ""
        switch section.index {
        case 0:
            key = self.masterIndexes[self.selectedMasterIndex]
        default:
            key = section.series[section.selectedIndex].key
        }
        guard let attributes = section.getTitleAttributesByIndex(index, seriesKey: key) else {
            return nil
        }
        var start = 0
        for (title, color) in attributes {
            titleString.append(NSAttributedString(string: title))
            let range = NSMakeRange(start, title.ch_length)
            let colorAttribute = [NSAttributedStringKey.foregroundColor: color]
            titleString.addAttributes(colorAttribute, range: range)
            start += title.ch_length
        }
        return titleString
    }
    
    func kLineChart(chart: CHKLineChartView, didSelectAt index: Int, item: CHChartItem) {
        let data = self.chartPoints[index]
        self.topView.update(data: data)
    }
    
    func kLineChart(chart: CHKLineChartView, didFlipPageSeries section: CHSection, series: CHSeries, seriesIndex: Int) {
        switch section.index {
        case 1:
            self.selectedAssistIndex1 = self.assistIndexes.index(of: series.key) ?? self.selectedAssistIndex1
        case 2:
            self.selectedAssistIndex2 = self.assistIndexes.index(of: series.key) ?? self.selectedAssistIndex2
        default:
            break
        }
    }
}

extension ChartCustomViewController {
    /// 读取用户自定义样式
    ///
    /// - Returns: CHKLineChartStyle
    func loadUserStyle() -> CHKLineChartStyle {
//        return CHKLineChartStyle.customDark
//        return CHKLineChartStyle.customLight  
        
        let styleManager = KLineChartStyleManager.shared
        
        let style = CHKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor(hex: styleManager.lineColor)
        style.textColor = UIColor(hex: styleManager.textColor)
        style.selectedBGColor = UIColor(white: 0.4, alpha: 1)
        style.selectedTextColor = UIColor(hex: styleManager.selectedTextColor)
        style.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        style.isInnerYAxis = styleManager.isInnerYAxis
        
        if styleManager.showYAxisLabel == "Left" {
            style.yAxisShowPosition = .left
            style.padding = UIEdgeInsets(top: 16, left: 0, bottom: 4, right: 8)
        } else {
            style.yAxisShowPosition = .right
            style.padding = UIEdgeInsets(top: 16, left: 8, bottom: 4, right: 0)
        }
        
        style.algorithms.append(CHChartAlgorithm.timeline)
        
        /***** 配置分区样式 *****/
        
        /// 主图
        let upcolor = (UIColor.ch_hex(styleManager.upColor), true)
        let downcolor = (UIColor.ch_hex(styleManager.downColor), true)
        
        let priceSection = CHSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.titleShowOutSide = true
        priceSection.valueType = .master
        priceSection.key = "master"
        priceSection.hidden = false
        priceSection.ratios = 3
        priceSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        
        /// 副图1
        let assistSection1 = CHSection()
        assistSection1.backgroundColor = style.backgroundColor
        assistSection1.valueType = .assistant
        assistSection1.key = "assist1"
        assistSection1.hidden = false
        assistSection1.ratios = 1
        assistSection1.paging = true
        assistSection1.yAxis.tickInterval = 4
        assistSection1.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        
        /// 副图2
        let assistSection2 = CHSection()
        assistSection2.backgroundColor = style.backgroundColor
        assistSection2.valueType = .assistant
        assistSection2.key = "assist2"
        assistSection2.hidden = false
        assistSection2.ratios = 1
        assistSection2.paging = true
        assistSection2.yAxis.tickInterval = 4
        assistSection2.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        
        /***** 添加主图固定线段 *****/
        
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
        priceSection.series.append(timelineSeries)
        priceSection.series.append(priceSeries)
        
        /***** 读取用户配置线段 *****/
        
        let seriesParams = SeriesParamList.shared.loadUserData()
        for series in seriesParams {
            if series.hidden {
                continue
            }
            style.algorithms.append(contentsOf: series.getAlgorithms())
            
            series.appendIn(masterSection: priceSection, assistSections: assistSection1, assistSection2)
        }
        
        style.sections.append(priceSection)
        if assistSection1.series.count > 0 {
            style.sections.append(assistSection1)
        }
        
        if assistSection2.series.count > 0 {
            style.sections.append(assistSection2)
        }
        
        // 设置图表外的背景色
        self.view.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        self.topView.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        self.bottomBar.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        
        return style
    }
}

extension ChartCustomViewController: SeriesSettingListViewControllerDelegate {
    func updateSeriesSettingParams() {
        self.chartView.resetStyle(style: self.loadUserStyle())
        self.handleChartIndexChanged()
    }
}

extension ChartCustomViewController: ChartStyleSettingViewControllerDelegate {
    func updateChartStyle(styleParam: KLineChartStyleManager) {
        self.chartView.resetStyle(style: self.loadUserStyle())
        self.handleChartIndexChanged()
    }
}

extension ChartCustomViewController {
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if toInterfaceOrientation.isPortrait {
            self.chartView.sections[1].yAxis.tickInterval = 3
            self.chartView.sections[2].yAxis.tickInterval = 3
        } else {
            self.chartView.sections[1].yAxis.tickInterval = 1
            self.chartView.sections[2].yAxis.tickInterval = 1
        }
        self.chartView.reloadData()
    }
}
