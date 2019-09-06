
import UIKit

class ChartTableViewCell: UITableViewCell {
    
    @IBOutlet var labelCurrency: UILabel!
    @IBOutlet var chartView: BMKLineChartView!
    @IBOutlet var segTimes: UISegmentedControl!
    @IBOutlet var indicatorView: UIActivityIndicatorView!
    
    static let identifier = "ChartTableViewCellID"
    
    var datas = [ChartPoint]()
    
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
    
    func reloadData(datas: [ChartPoint]) {
        self.datas = datas
        self.chartView.reloadData()
    }
    
    @IBAction func handleTimeSegmentChange(sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        self.updateTime?(index)
    }
}

extension ChartTableViewCell: BMKLineChartDelegate {
    
    func numberOfPointsInKLineChart(chart: BMKLineChartView) -> Int {
        return self.datas.count
    }
    
    func kLineChart(chart: BMKLineChartView, valueForPointAtIndex index: Int) -> BMKLineChartItem {
        let data = self.datas[index]
        let item = BMKLineChartItem()
        item.time = data.time
        item.openPrice = CGFloat(data.openPrice)
        item.closePrice = CGFloat(data.closePrice)
        item.highPrice = CGFloat(data.highPrice)
        item.lowPrice = CGFloat(data.lowPrice)
        item.vol = CGFloat(data.vol)
        return item
    }
    
    func widthForYAxisLabelInKLineChart(in chart: BMKLineChartView) -> CGFloat {
        return chart.DefaultYAxisLabelWidth
    }
    
    func kLineChart(chart: BMKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: BMKLineSection) -> String {
        return value.bm_toString(maxF: section.decimal)
    }
    
    func kLineChart(chart: BMKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        let data = self.datas[index]
        let timestamp = data.time
        var time = Date.bm_timeStringOfStamp(timestamp, format: "HH:mm")
        if time == "00:00" {
            time = Date.bm_timeStringOfStamp(timestamp, format: "MM-dd")
        }
        return time
    }
    
    func heightForXAxisInKLineChart(in chart: BMKLineChartView) -> CGFloat {
        return 16
    }
}

extension BMKLineChartStyle {

    static var chartInCell: BMKLineChartStyle {
        let style = BMKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor(white: 0.7, alpha: 1)
        style.backgroundColor = UIColor.white
        style.textColor = UIColor(white: 0.5, alpha: 1)
        style.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        style.isInnerYAxis = false
        style.yAxisShowPosition = .right
        style.showXAxisLabel = true
        style.borderWidth = (0.5, 0, 0.5, 0)
        style.isShowPlotAll = true
        style.enablePan = false
        style.enableTap = false
        style.enablePinch = false
        style.algorithms = [BMKLineIndexAlgorithm.timeline, BMKLineIndexAlgorithm.ma(5), BMKLineIndexAlgorithm.ma(10), BMKLineIndexAlgorithm.ma(30)]
        
        let upColor = (UIColor.bm_hex(0x5BA267), true)
        let downColor = (UIColor.bm_hex(0xB1414C), true)
        
        let priceSection = BMKLineSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.isShowTitleOutside = false
        priceSection.isShowTitle = false
        priceSection.type = .master
        priceSection.key = "price"
        priceSection.isHidden = false
        priceSection.ratios = 1
        priceSection.yAxis.referenceStyle = .solid(color: UIColor(white: 0.9, alpha: 1))
        priceSection.xAxis.referenceStyle = .solid(color: UIColor(white: 0.9, alpha: 1))
        priceSection.padding = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        
        let timelineSeries = BMKLineSeries.getTimelinePrice(
            color: UIColor.bm_hex(0xAE475C),
            section: priceSection,
            showUltimateValue: true,
            ultimateValueStyle: .circle(UIColor.bm_hex(0xAE475C), true),
            lineWidth: 2
        )
        timelineSeries.hidden = true
        
        let maColor = [
            UIColor.bm_hex(0x4E9CC1),
            UIColor.bm_hex(0xF7A23B),
            UIColor.bm_hex(0xF600FF),
        ]
        
        /// 蜡烛线
        let priceSeries = BMKLineSeries.getCandlePrice(
            upStyle: upColor,
            downStyle: downColor,
            titleColor: UIColor(white: 0.5, alpha: 1),
            section: priceSection,
            showUltimateValue: true,
            ultimateValueStyle: .arrow(UIColor(white: 0.5, alpha: 1))
        )
        
        // MA 线
        let priceMASeries = BMKLineSeries.getPriceMA(
            isEMA: false,
            num: [5, 10, 30],
            colors:maColor,
            section: priceSection
        )
        priceMASeries.hidden = false
        
        // EMA 线
        let priceEMASeries = BMKLineSeries.getPriceMA(
            isEMA: true,
            num: [5, 10, 30],
            colors: maColor,
            section: priceSection
        )
        priceEMASeries.hidden = true
        
        priceSection.seriesArray = [timelineSeries, priceSeries, priceMASeries, priceEMASeries]
        
        style.sections = [priceSection]
        
        return style
    }
}
