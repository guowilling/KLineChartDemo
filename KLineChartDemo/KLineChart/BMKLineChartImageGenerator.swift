
import UIKit

public class BMKLineChartImageGenerator: NSObject {

    /// (时间戳, 收盘价格)
    public var values: [(Int, Double)] = []
    
    public var chartView: BMKLineChartView!
    
    public var style: BMKLineChartStyle!
    
    public static let shared: BMKLineChartImageGenerator = {
        let generator = BMKLineChartImageGenerator()
        return generator
    }()
    
    public override init() {
        super.init()
        
        self.chartView = BMKLineChartView(frame: CGRect.zero)
        self.chartView.delegate = self
        self.style = .timelineImgStyle
    }
    
    public func generateImage(
        by values: [(Int, Double)],
        lineWidth: CGFloat = 1,
        backgroundColor: UIColor = UIColor.white,
        lineColor: UIColor = UIColor.lightGray,
        size: CGSize
        ) -> UIImage
    {
        self.values = values
        
        self.style.backgroundColor = backgroundColor
        
        let section = self.style.sections[0]
        section.backgroundColor = backgroundColor
        
        let model = section.seriesArray[0].chartModels[0]
        model.upStyle = (lineColor, true)
        model.downStyle = (lineColor, true)
        model.lineWidth = lineWidth
        
        var frame = self.chartView.frame
        frame.size.width = size.width
        frame.size.height = size.height
        self.chartView.frame = frame
        self.chartView.style = self.style
        self.chartView.reloadData()
        
        return self.chartView.image
    }
}

extension BMKLineChartImageGenerator: BMKLineChartDelegate {
    
    public func numberOfPointsInKLineChart(chart: BMKLineChartView) -> Int {
        return self.values.count
    }
    
    public func kLineChart(chart: BMKLineChartView, valueForPointAtIndex index: Int) -> BMKLineChartItem {
        let data = self.values[index]
        let chartItem = BMKLineChartItem()
        chartItem.time = Int(data.0 / 1000)
        chartItem.closePrice = CGFloat(data.1)
        return chartItem
    }
    
    public func widthForYAxisLabelInKLineChart(in chart: BMKLineChartView) -> CGFloat {
        return chart.DefaultYAxisLabelWidth
    }
    
    public func kLineChart(chart: BMKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: BMKLineSection) -> String {
        return ""
    }
    
    public func kLineChart(chart: BMKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        return ""
    }
    
    public func heightForXAxisInKLineChart(in chart: BMKLineChartView) -> CGFloat {
        return 0
    }
}

extension BMKLineChartStyle {
    
    public static var timelineImgStyle: BMKLineChartStyle {
        let style = BMKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor.clear
        style.backgroundColor = UIColor.bm_hex(0xF5F5F5)
        style.textColor = UIColor(white: 0.8, alpha: 1)
        style.padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        style.isInnerYAxis = true
        style.yAxisShowPosition = .none
        style.showXAxisOnSection = 0
        style.showXAxisLabel = false
        style.isShowPlotAll = true
        style.enablePan = false
        style.enableTap = false
        style.enablePinch = false
        style.algorithms = [BMKLineIndexAlgorithm.timeline]
        
        let priceSection = BMKLineSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.isShowTitle = false
        priceSection.isShowTitleOutside = false
        priceSection.type = .master
        priceSection.key = "price"
        priceSection.isHidden = false
        priceSection.ratios = 1
        priceSection.yAxis.referenceStyle = .none
        priceSection.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let timelineSeries = BMKLineSeries.getTimelinePrice(
            color: UIColor.bm_hex(0xA4AAB3),
            section: priceSection,
                    showUltimateValue: true,
            ultimateValueStyle: .none,
            lineWidth: 1
        )
        priceSection.seriesArray = [timelineSeries]
        style.sections = [priceSection]
        return style
    }
}
