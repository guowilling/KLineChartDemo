
import UIKit
//import CHKLineChartKit

class ChartSimpleViewController: UIViewController {
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    @IBOutlet weak var kLineChartView: BMKLineChartView!
    
    var chartPoints: [ChartPoint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.kLineChartView.delegate = self
        self.kLineChartView.style = .simpleLineDark
        
        self.fetchChartDatas(symbol: "BTC-USD", type: .min15)
    }
    
    func fetchChartDatas(symbol: String, type: ChartPointDurationType) {
        self.indicatorView.startAnimating()
        self.indicatorView.isHidden = false
        ChartPointManager.shared.getKLineChartData(exPair: symbol, timeType: type) { [weak self] (success, chartPoints) in
            self?.indicatorView.isHidden = true
            self?.indicatorView.stopAnimating()
            if success && chartPoints.count > 0 {
                self?.chartPoints = chartPoints
                self?.kLineChartView.reloadData(toPosition: .tail)
            }
        }
    }
}

extension ChartSimpleViewController: BMKLineChartDelegate {
    
    func numberOfPointsInKLineChart(chart: BMKLineChartView) -> Int {
        return self.chartPoints.count
    }
    
    func kLineChart(chart: BMKLineChartView, valueForPointAtIndex index: Int) -> BMKLineChartItem {
        let point = self.chartPoints[index]
        let chartItem = BMKLineChartItem()
        chartItem.time = point.time
        chartItem.closePrice = CGFloat(point.closePrice)
        return chartItem
    }
    
    func kLineChart(chart: BMKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: BMKLineSection) -> String {
        return value.bm_toString(maxF: section.decimal)
    }
    
    func kLineChart(chart: BMKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        let point = self.chartPoints[index]
        let timestamp = point.time
        var time = Date.bm_timeStringOfStamp(timestamp, format: "HH:mm")
        if time == "00:00" {
            time = Date.bm_timeStringOfStamp(timestamp, format: "MM-dd")
        }
        return time
    }
    
    func kLineChart(chart: BMKLineChartView, decimalAt section: Int) -> Int {
        return 2
    }
    
    func widthForYAxisLabelInKLineChart(in chart: BMKLineChartView) -> CGFloat {
        return chart.DefaultYAxisLabelWidth
    }
    
    func heightForXAxisInKLineChart(in chart: BMKLineChartView) -> CGFloat {
        return 16
    }
    
}
