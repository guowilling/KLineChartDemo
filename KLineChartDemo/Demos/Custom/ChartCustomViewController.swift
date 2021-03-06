
import UIKit
//import CHKLineChartKit

class ChartCustomViewController: UIViewController {
    
    /// 不显示
    static let Hide: String = "隐藏"
    
    /// 时间周期
    let times: [ChartPointDurationType] = [.min5, .min15, .hour1, .hour6, .day]
    
    /// 主图线段
    let masterLines: [String] = [BMKLineSeriesKey.candle, BMKLineSeriesKey.timeline]
    
    /// 主图指标
    let masterIndexes: [String] = [BMKLineSeriesKey.ma,
                                   BMKLineSeriesKey.ema,
                                   BMKLineSeriesKey.boll,
                                   BMKLineSeriesKey.sar,
                                   Hide]
    
    /// 副图指标
    let assistIndexes: [String] = [BMKLineSeriesKey.volume,
                                   BMKLineSeriesKey.macd,
                                   BMKLineSeriesKey.kdj,
                                   BMKLineSeriesKey.rsi,
                                   Hide]
    
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
    var chartPoints = [ChartPoint]()
    
    /// X 轴的前一天, 用于对比是否夸日
    var chartXAxisPrevDay: String = ""
    
    lazy var chartView: BMKLineChartView = {
        let view = BMKLineChartView(frame: .zero)
        view.style = self.loadUserStyle()
        view.delegate = self
        return view
    }()
    
    lazy var topView: ChartCustomTopView = {
//        let view = KLineTopView.loadFromNib()
        let view = ChartCustomTopView()
        return view
    }()
    
    lazy var optionView: ChartCustomOptionView = {
        let view = ChartCustomOptionView(frame: .zero)
        
        view.timeChangedClosure = { [weak self] str in
            guard let self = self else { return }
            if let timeType = ChartPointDurationType.init(rawValue: str), let index = self.times.firstIndex(of: timeType) {
                self.selectedMasterLine = 0
                self.selectedTime = index
            } else {
                // 分时线
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
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self.buttonExPairs.setTitle(self.exPairs[self.selectedExPair], for: .normal)
        self.selectedExPair = 0
        self.selectedTime = 0
        self.selectedMasterLine = 0
        self.selectedMasterIndex = 0
        self.selectedAssistIndex1 = 0
        self.selectedAssistIndex2 = 1
        
        self.handleChartIndexChanged()
        
        self.fetchKLineChartData()
    }
    
    func setupUI() {
        self.view.backgroundColor = UIColor.white
        
        self.navigationItem.titleView = self.buttonExPairs
        
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        self.view.addSubview(scrollView)
        
        scrollView.addSubview(self.topView)
        self.topView.frame = CGRect(x: 10, y: 5, width: scrollView.frame.width - 20, height: 75)
        
        scrollView.addSubview(self.optionView)
        self.optionView.frame = CGRect(x: 0, y: topView.frame.maxY, width: scrollView.frame.width, height: 30)
        
        scrollView.addSubview(self.chartView)
        self.chartView.frame = CGRect(x: 0, y: optionView.frame.maxY, width: scrollView.frame.width, height: 500)
        
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
        
        scrollView.contentSize = CGSize(width: 0, height: 777)
    }
    
    func fetchKLineChartData() {
        self.indicatorView.startAnimating()
        self.indicatorView.isHidden = false
        let symbol = self.exPairs[self.selectedExPair]
        ChartPointManager.shared.getKLineChartData(exPair: symbol, timeType: self.times[self.selectedTime]) { [weak self] (success, chartPoints) in
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

extension ChartCustomViewController: BMKLineChartDelegate {
    
    func initialRangeInKLineChart(in chart: BMKLineChartView) -> Int {
        return 50
    }
    
    func numberOfPointsInKLineChart(chart: BMKLineChartView) -> Int {
        return self.chartPoints.count
    }
    
    func kLineChart(chart: BMKLineChartView, valueForPointAtIndex index: Int) -> BMKLineChartItem {
        let point = self.chartPoints[index]
        let item = BMKLineChartItem()
        item.time = point.time
        item.openPrice = CGFloat(point.openPrice)
        item.highPrice = CGFloat(point.highPrice)
        item.lowPrice = CGFloat(point.lowPrice)
        item.closePrice = CGFloat(point.closePrice)
        item.vol = CGFloat(point.vol)
        return item
    }
    
    func kLineChart(chart: BMKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: BMKLineSection) -> String {
        var lable = ""
        if section.key == "volume" {
            if value / 1000 > 1 {
                lable = (value / 1000).bm_toString(maxF: section.decimal) + "K"
            } else {
                lable = value.bm_toString(maxF: section.decimal)
            }
        } else {
            lable = value.bm_toString(maxF: section.decimal)
        }
        return lable
    }
    
    func kLineChart(chart: BMKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        let timestamp = self.chartPoints[index].time
        let dayText = Date.bm_timeStringOfStamp(timestamp, format: "MM-dd")
        let timeText = Date.bm_timeStringOfStamp(timestamp, format: "HH:mm")
        var lable = ""
        if dayText != self.chartXAxisPrevDay && index > 0 {
            lable = dayText
        } else {
            lable = timeText
        }
        self.chartXAxisPrevDay = dayText
        return lable
    }
    
    func kLineChart(chart: BMKLineChartView, decimalAt section: Int) -> Int {
        if section == 0 {
            return 4
        } else {
            return 2
        }
    }
    
    func widthForYAxisLabelInKLineChart(in chart: BMKLineChartView) -> CGFloat {
        return 60
    }
    
    func kLineChart(chart: BMKLineChartView, titleForHeaderInSection section: BMKLineSection, index: Int, item: BMKLineChartItem) -> NSAttributedString? {
        let titleString = NSMutableAttributedString()
        var key = ""
        switch section.index {
        case 0:
            key = self.masterIndexes[self.selectedMasterIndex]
        default:
            key = section.seriesArray[section.selectedIndex].key
        }
        guard let attributes = section.getTitlesAndAttributesByIndex(index, seriesKey: key) else {
            return nil
        }
        var start = 0
        for (title, color) in attributes {
            titleString.append(NSAttributedString(string: title))
            let range = NSMakeRange(start, title.bm_length)
            let colorAttribute = [NSAttributedString.Key.foregroundColor: color]
            titleString.addAttributes(colorAttribute, range: range)
            start += title.bm_length
        }
        return titleString
    }
    
    func kLineChart(chart: BMKLineChartView, didSelectAt index: Int, item: BMKLineChartItem) {
        NSLog("selected index = \(index)")
        NSLog("selected item closePrice = \(item.closePrice)")
//        let point = self.chartPoints[index]
//        self.topView.update(point: point)
    }
    
    func kLineChart(chart: BMKLineChartView, didFlipPageSeries section: BMKLineSection, series: BMKLineSeries, seriesIndex: Int) {
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
    func loadUserStyle() -> BMKLineChartStyle {
//        return CHKLineChartStyle.customDark
//        return CHKLineChartStyle.customLight  
        
        let styleManager = KLineChartStyleManager.shared
        
        let style = BMKLineChartStyle()
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
        
        style.algorithms.append(BMKLineIndexAlgorithm.timeline)
        
        /***** 配置分区样式 *****/
        
        /// 主图
        let upcolor = (UIColor.bm_hex(styleManager.upColor), true)
        let downcolor = (UIColor.bm_hex(styleManager.downColor), true)
        
        let priceSection = BMKLineSection()
        priceSection.type = .master
        priceSection.key = "master"
        priceSection.ratios = 3
        priceSection.isHidden = false
        priceSection.isShowTitleOutside = true
        priceSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        priceSection.backgroundColor = style.backgroundColor
        
        /// 副图1
        let assistSection1 = BMKLineSection()
        assistSection1.type = .assistant
        assistSection1.key = "assist1"
        assistSection1.ratios = 1
        assistSection1.isHidden = false
        assistSection1.isPageable = false
        assistSection1.yAxis.tickInterval = 4
        assistSection1.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        assistSection1.backgroundColor = style.backgroundColor
        
        /// 副图2
        let assistSection2 = BMKLineSection()
        assistSection2.type = .assistant
        assistSection2.key = "assist2"
        assistSection2.ratios = 1
        assistSection2.isHidden = false
        assistSection2.isPageable = true
        assistSection2.yAxis.tickInterval = 4
        assistSection2.padding = UIEdgeInsets(top: 16, left: 0, bottom: 8, right: 0)
        assistSection2.backgroundColor = style.backgroundColor
        
        /***** 添加主图固定线段 *****/
        
        /// 时分线
        let timelineSeries = BMKLineSeries.getTimelinePrice(
            color: UIColor.bm_hex(0xAE475C),
            section: priceSection,
                    showUltimateValue: true,
            ultimateValueStyle: .circle(UIColor.bm_hex(0xAE475C), true),
            lineWidth: 2)
        timelineSeries.hidden = true
        
        /// 蜡烛线
        let priceSeries = BMKLineSeries.getCandlePrice(
            upStyle: upcolor,
            downStyle: downcolor,
            titleColor: UIColor(white: 0.8, alpha: 1),
            section: priceSection,
            showUltimateValue: true,
            ultimateValueStyle: .arrow(UIColor(white: 0.8, alpha: 1)))
        priceSeries.showTitle = true
        priceSeries.chartModels.first?.ultimateValueStyle = .arrow(UIColor(white: 0.8, alpha: 1))
        priceSection.seriesArray.append(timelineSeries)
        priceSection.seriesArray.append(priceSeries)
        
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
        if assistSection1.seriesArray.count > 0 {
            style.sections.append(assistSection1)
        }
        
        if assistSection2.seriesArray.count > 0 {
            style.sections.append(assistSection2)
        }
        
        // 设置图表外的背景色
        self.view.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        self.topView.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        self.optionView.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        self.optionView.setThemeColor(hex: styleManager.backgroundColor)
        self.bottomBar.backgroundColor = UIColor(hex: styleManager.backgroundColor)
        
        if styleManager.backgroundColor == 0xffffff {
            self.indicatorView.style = .gray
        } else {
            self.indicatorView.style = .white
        }
        
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
