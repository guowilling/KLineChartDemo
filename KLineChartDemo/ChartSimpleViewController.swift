
import UIKit
//import CHKLineChartKit

class ChartSimpleViewController: UIViewController {
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var kLineChartView: CHKLineChartView!
    
    var chartPoints = [KLineChartPoint]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.kLineChartView.delegate = self
        self.kLineChartView.style = .simpleLineDark
        
        self.fetchChartDatas(symbol: "BTC-USD", type: "15min")
    }
    
    func fetchChartDatas(symbol: String, type: String) {
        self.indicatorView.startAnimating()
        self.indicatorView.isHidden = false
        ChartDataFetcher.shared.getKLineChartData(exPair: symbol, timeType: type) { [weak self] (success, chartPoints) in
            if success && chartPoints.count > 0 {
                self?.chartPoints = chartPoints
                self?.kLineChartView.reloadData(toPosition: .end)
            }
            self?.indicatorView.stopAnimating()
            self?.indicatorView.isHidden = true
        }
    }
}

extension ChartSimpleViewController: CHKLineChartDelegate {
    
    func numberOfPointsInKLineChart(chart: CHKLineChartView) -> Int {
        return self.chartPoints.count
    }
    
    func kLineChart(chart: CHKLineChartView, valueForPointAtIndex index: Int) -> CHChartItem {
        let point = self.chartPoints[index]
        let chartItem = CHChartItem()
        chartItem.time = point.time
        chartItem.closePrice = CGFloat(point.closePrice)
        return chartItem
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: CHSection) -> String {
        return value.ch_toString(maxF: section.decimal)
    }
    
    func kLineChart(chart: CHKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        let point = self.chartPoints[index]
        let timestamp = point.time
        var time = Date.ch_getTimeByStamp(timestamp, format: "HH:mm")
        if time == "00:00" {
            time = Date.ch_getTimeByStamp(timestamp, format: "MM-dd")
        }
        return time
    }
    
    func kLineChart(chart: CHKLineChartView, decimalAt section: Int) -> Int {
        return 2
    }
    
    func widthForYAxisLabelInKLineChart(in chart: CHKLineChartView) -> CGFloat {
        return chart.kYAxisLabelWidth
    }
    
    func heightForXAxisInKLineChart(in chart: CHKLineChartView) -> CGFloat {
        return 16
    }
    
    func kLineChart(chart: CHKLineChartView, didSelectAt index: Int, item: CHChartItem) {
        NSLog("selected index = \(index)")
        NSLog("selected item closePrice = \(item.closePrice)")
    }
}
