
import UIKit
//import CHKLineChartKit

class ChartCustomViewController: UIViewController {
    
    /// 不显示
    static let Hide: String = ""
    
    /// 时间周期
    let times: [KLineTimeType] = [.min5, .min15, .hour1, .hour6, .day]
    
    /// 主图线段
    let masterLines: [String] = [CHSeriesKey.candle, CHSeriesKey.timeline]
    
    /// 主图指标
    let masterIndexes: [String] = [CHSeriesKey.ma, CHSeriesKey.ema, CHSeriesKey.sar, CHSeriesKey.boll, CHSeriesKey.sam, Hide]
    
    /// 副图指标
    let assistIndexes: [String] = [CHSeriesKey.volume, CHSeriesKey.sam, CHSeriesKey.kdj, CHSeriesKey.macd, CHSeriesKey.rsi, Hide]
    
    /// 选择交易对
    let exPairs: [String] = ["BTC-USD", "ETH-USD", "LTC-USD", "LTC-BTC", "ETH-BTC"]
    
    /// 已选周期
    var selectedTime: Int = 0
    
    /// 已选交易对
    var selectedExPair: Int = 0
    
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
        let view = CHKLineChartView(frame: .zero)
        view.style = self.loadUserStyle()
        view.delegate = self
        return view
    }()
    
    lazy var topView: KLineTopView = {
        let view = KLineTopView.loadFromNib()
        return view
    }()
    
    lazy var optionView: KLineOptionView = {
        let view = KLineOptionView(frame: .zero)
        
        view.timeChangedClosure = { [weak self] str in
            guard let self = self else { return }
            if let timeType = KLineTimeType.init(rawValue: str), let index = self.times.firstIndex(of: timeType) {
                // 分时线
                self.selectedMasterLine = 0
                self.selectedTime = index
            } else {
                self.selectedMasterLine = 1
                self.selectedTime = 1
            }
            self.handleChartIndexChanged()
            self.fetchKLineChartData()
        }
        
        view.masterIndexChangedClosure = { [weak self] str in
            guard let self = self else { return }
            if self.masterIndexes.contains(str) {
                if let index = self.masterIndexes.firstIndex(of: str) {
                    self.selectedMasterIndex = index
                    self.handleChartIndexChanged()
                    self.chartView.reloadData()
                }
            }
        }
        
        view.assistIndexChangedClosure = { [weak self] str in
            guard let self = self else { return }
            if self.assistIndexes.contains(str) {
                if let index = self.assistIndexes.firstIndex(of: str) {
                    self.selectedAssistIndex2 = index
                    self.handleChartIndexChanged()
                    self.chartView.reloadData()
                }
            }
        }
        
        return view
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
    
    lazy var indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .white)
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
        self.view.backgroundColor = UIColor.white
        
        self.navigationItem.titleView = self.buttonExPairs
        
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.backgroundColor = UIColor(hex: 0x232732)
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        self.view.addSubview(scrollView)
        
        scrollView.addSubview(self.topView)
        self.topView.frame = CGRect(x: 10, y: 5, width: scrollView.frame.width - 20, height: 75)
        
        scrollView.addSubview(self.optionView)
        self.optionView.frame = CGRect(x: 0, y: topView.frame.maxY, width: scrollView.frame.width, height: 30)
        
        scrollView.addSubview(self.chartView)
        self.chartView.frame = CGRect(x: 0, y: optionView.frame.maxY, width: scrollView.frame.width, height: 450)
        
        scrollView.addSubview(self.bottomBar)
        self.bottomBar.frame = CGRect(x: 0, y: chartView.frame.maxY + 5, width: scrollView.frame.width, height: 44)
        
        self.bottomBar.addSubview(self.buttonIndexParams)
        self.bottomBar.addSubview(self.buttonStyle)
        self.buttonIndexParams.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(self.buttonStyle)
            make.height.equalToSuperview()
        }
        self.buttonStyle.snp.makeConstraints { (make) in
            make.left.equalTo(self.buttonIndexParams.snp.right)
            make.right.equalToSuperview()
            make.width.equalTo(self.buttonIndexParams)
            make.height.equalToSuperview()
        }
        
        self.chartView.addSubview(self.indicatorView)
        self.indicatorView.snp.makeConstraints { (make) in
            make.center.equalTo(self.chartView)
        }
        
        scrollView.sendSubviewToBack(self.chartView)
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
                self?.topView.update(point: chartPoints.last!)
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
        let alertC = UIAlertController.init(title: "ExPairs", message: nil, preferredStyle: .alert)
        let action0 = UIAlertAction.init(title: "BTC-USD", style: .default) { (_) in
            self.selectedExPair = self.exPairs.firstIndex(of: "BTC-USD")!
            self.buttonExPairs.setTitle("BTC-USD", for: .normal)
            self.fetchKLineChartData()
        }
        let action1 = UIAlertAction.init(title: "ETH-USD", style: .default) { (_) in
            self.selectedExPair = self.exPairs.firstIndex(of: "ETH-USD")!
            self.buttonExPairs.setTitle("ETH-USD", for: .normal)
            self.fetchKLineChartData()
            
        }
        let action2 = UIAlertAction.init(title: "LTC-USD", style: .default) { (_) in
            self.selectedExPair = self.exPairs.firstIndex(of: "LTC-USD")!
            self.buttonExPairs.setTitle("LTC-USD", for: .normal)
            self.fetchKLineChartData()
        }
        let action3 = UIAlertAction.init(title: "LTC-BTC", style: .default) { (_) in
            self.selectedExPair = self.exPairs.firstIndex(of: "LTC-BTC")!
            self.buttonExPairs.setTitle("LTC-BTC", for: .normal)
            self.fetchKLineChartData()
        }
        let action4 = UIAlertAction.init(title: "ETH-BTC", style: .default) { (_) in
            self.selectedExPair = self.exPairs.firstIndex(of: "ETH-BTC")!
            self.buttonExPairs.setTitle("ETH-BTC", for: .normal)
            self.fetchKLineChartData()
        }
        let actionC = UIAlertAction.init(title: "取消", style: .destructive)
        alertC.addAction(action0)
        alertC.addAction(action1)
        alertC.addAction(action2)
        alertC.addAction(action3)
        alertC.addAction(action4)
        alertC.addAction(actionC)
        self.present(alertC, animated: true, completion: nil)
    }
    
    @objc func buttonIndexParamsAction() {
        let vc = SeriesSettingListViewController()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func buttonStyleAction() {
        let vc = StyleSettingViewController()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ChartCustomViewController: CHKLineChartDelegate {
    
    func initialRangeInKLineChart(in chart: CHKLineChartView) -> Int {
        return 50
    }
    
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
            let colorAttribute = [NSAttributedString.Key.foregroundColor: color]
            titleString.addAttributes(colorAttribute, range: range)
            start += title.ch_length
        }
        return titleString
    }
    
    func kLineChart(chart: CHKLineChartView, didSelectAt index: Int, item: CHChartItem) {
        let data = self.chartPoints[index]
        self.topView.update(point: data)
    }
    
    func kLineChart(chart: CHKLineChartView, didFlipPageSeries section: CHSection, series: CHSeries, seriesIndex: Int) {
        switch section.index {
        case 1:
            self.selectedAssistIndex1 = self.assistIndexes.firstIndex(of: series.key) ?? self.selectedAssistIndex1
        case 2:
            self.selectedAssistIndex2 = self.assistIndexes.firstIndex(of: series.key) ?? self.selectedAssistIndex2
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
