
import UIKit
//import CHKLineChartKit

class ChartTableViewCell: UITableViewCell {
    
    @IBOutlet var labelCurrency: UILabel!
    @IBOutlet var chartView: CHKLineChartView!
    @IBOutlet var segTimes: UISegmentedControl!
    @IBOutlet var indicatorView: UIActivityIndicatorView!
    
    static let identifier = "ChartTableViewCellID"
    
    var datas = [KLineChartPoint]()
    
    var time: String = "15min"
    
    var updateTime: ((Int) -> Void)?
    
    var currency: String = "" {
        didSet {
            self.labelCurrency.text = self.currency.uppercased()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.chartView.style = .chartInCell
        self.chartView.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func reloadData(datas: [KLineChartPoint]) {
        self.datas = datas
        self.chartView.reloadData()
    }

    @IBAction func handleTimeSegmentChange(sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        self.updateTime?(index)
    }
}

extension CHKLineChartStyle {

    static var chartInCell: CHKLineChartStyle {
        let style = CHKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor(white: 0.7, alpha: 1)
        style.backgroundColor = UIColor.white
        style.textColor = UIColor(white: 0.5, alpha: 1)
        style.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        style.isInnerYAxis = false
        style.showYAxisLabel = .right
        style.showXAxisLabel = true
        style.borderWidth = (0.5, 0, 0.5, 0)
        style.isShowAll = true
        style.enablePan = false
        style.enableTap = false
        style.enablePinch = false
        style.algorithms = [CHChartAlgorithm.timeline, CHChartAlgorithm.ma(5), CHChartAlgorithm.ma(10), CHChartAlgorithm.ma(30)]
        
        let upColor = (UIColor.ch_hex(0x5BA267), true)
        let downColor = (UIColor.ch_hex(0xB1414C), true)
        
        let priceSection = CHSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.titleShowOutSide = false
        priceSection.showTitle = false
        priceSection.valueType = .master
        priceSection.key = "price"
        priceSection.hidden = false
        priceSection.ratios = 1
        priceSection.yAxis.referenceStyle = .solid(color: UIColor(white: 0.9, alpha: 1))
        priceSection.xAxis.referenceStyle = .solid(color: UIColor(white: 0.9, alpha: 1))
        priceSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        
        let timelineSeries = CHSeries.getTimelinePrice(color: UIColor.ch_hex(0xAE475C),
                                                       section: priceSection,
                                                       showGuide: true,
                                                       ultimateValueStyle: .circle(UIColor.ch_hex(0xAE475C), true),
                                                       lineWidth: 2)
        timelineSeries.hidden = true
        
        let maColor = [UIColor.ch_hex(0x4E9CC1),
                       UIColor.ch_hex(0xF7A23B),
                       UIColor.ch_hex(0xF600FF)]
        
        /// 蜡烛线
        let priceSeries = CHSeries.getCandlePrice(upStyle: upColor,
                                                  downStyle: downColor,
                                                  titleColor: UIColor(white: 0.5, alpha: 1),
                                                  section: priceSection,
                                                  showGuide: true,
                                                  ultimateValueStyle: .arrow(UIColor(white: 0.5, alpha: 1)))
        
        // MA 线
        let priceMASeries = CHSeries.getPriceMA(isEMA: false,
                                                num: [5, 10, 30],
                                                colors:maColor,
                                                section: priceSection)
        priceMASeries.hidden = false
        
        // EMA 线
        let priceEMASeries = CHSeries.getPriceMA(isEMA: true,
                                                 num: [5, 10, 30],
                                                 colors: maColor,
                                                 section: priceSection)
        priceEMASeries.hidden = true
        
        priceSection.series = [timelineSeries, priceSeries, priceMASeries, priceEMASeries]
        
        style.sections = [priceSection]
        
        return style
    }
}

extension ChartTableViewCell: CHKLineChartDelegate {
    
    func numberOfPointsInKLineChart(chart: CHKLineChartView) -> Int {
        return self.datas.count
    }
    
    func kLineChart(chart: CHKLineChartView, valueForPointAtIndex index: Int) -> CHChartItem {
        let data = self.datas[index]
        let item = CHChartItem()
        item.time = data.time
        item.openPrice = CGFloat(data.openPrice)
        item.highPrice = CGFloat(data.highPrice)
        item.lowPrice = CGFloat(data.lowPrice)
        item.closePrice = CGFloat(data.closePrice)
        item.vol = CGFloat(data.vol)
        return item
    }
    
    func widthForYAxisLabelInKLineChart(in chart: CHKLineChartView) -> CGFloat {
        return chart.kYAxisLabelWidth
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: CHSection) -> String {
        return value.ch_toString(maxF: section.decimal)
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        let data = self.datas[index]
        let timestamp = data.time
        var time = Date.ch_getTimeByStamp(timestamp, format: "HH:mm")
        if time == "00:00" {
            time = Date.ch_getTimeByStamp(timestamp, format: "MM-dd")
        }
        return time
    }
    
    func heightForXAxisInKLineChart(in chart: CHKLineChartView) -> CGFloat {
        return 16
    }
}

