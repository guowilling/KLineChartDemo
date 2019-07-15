
import UIKit

public class CHChartImageGenerator: NSObject {

    /// (时间戳, 收盘价格)
    public var values: [(Int, Double)] = []
    
    public var chartView: CHKLineChartView!
    
    public var style: CHKLineChartStyle = CHKLineChartStyle.timelineImgStyle
    
    public static let share: CHChartImageGenerator = {
        let generator = CHChartImageGenerator()
        return generator
    }()
    
    public override init() {
        super.init()
        
        self.chartView = CHKLineChartView(frame: CGRect.zero)
        self.chartView.style = CHKLineChartStyle.timelineImgStyle
        self.chartView.delegate = self
    }
    
    public func kLineImage(
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

extension CHChartImageGenerator: CHKLineChartDelegate {
    
    public func numberOfPointsInKLineChart(chart: CHKLineChartView) -> Int {
        return self.values.count
    }
    
    public func kLineChart(chart: CHKLineChartView, valueForPointAtIndex index: Int) -> CHChartItem {
        let data = self.values[index]
        let chartItem = CHChartItem()
        chartItem.time = Int(data.0 / 1000)
        chartItem.closePrice = CGFloat(data.1)
        return chartItem
    }
    
    public func widthForYAxisLabelInKLineChart(in chart: CHKLineChartView) -> CGFloat {
        return chart.DefaultYAxisLabelWidth
    }
    
    public func kLineChart(chart: CHKLineChartView, labelOnYAxisForValue value: CGFloat, atIndex index: Int, section: CHSection) -> String {
        return ""
    }
    
    public func kLineChart(chart: CHKLineChartView, labelOnXAxisForIndex index: Int) -> String {
        return ""
    }
    
    public func heightForXAxisInKLineChart(in chart: CHKLineChartView) -> CGFloat {
        return 0
    }
}

extension CHKLineChartStyle {
    public static var timelineImgStyle: CHKLineChartStyle {
        let style = CHKLineChartStyle()
        style.labelFont = UIFont.systemFont(ofSize: 10)
        style.lineColor = UIColor.clear
        style.backgroundColor = UIColor.ch_hex(0xF5F5F5)
        style.textColor = UIColor(white: 0.8, alpha: 1)
        style.padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        style.isInnerYAxis = true
        style.yAxisShowPosition = .none
        style.showXAxisOnSection = 0
        style.showXAxisLabel = false
        style.isShowAll = true
        style.enablePan = false
        style.enableTap = false
        style.enablePinch = false
        style.algorithms = [CHChartAlgorithm.timeline]
        
        let priceSection = CHSection()
        priceSection.backgroundColor = style.backgroundColor
        priceSection.isShowTitle = false
        priceSection.isShowTitleOutside = false
        priceSection.type = .master
        priceSection.key = "price"
        priceSection.isHidden = false
        priceSection.ratios = 1
        priceSection.yAxis.referenceStyle = .none
        priceSection.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let timelineSeries = CHSeries.getTimelinePrice(
            color: UIColor.ch_hex(0xA4AAB3),
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
