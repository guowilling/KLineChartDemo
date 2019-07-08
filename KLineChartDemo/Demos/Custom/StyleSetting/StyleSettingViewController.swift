
import UIKit

@objc protocol ChartStyleSettingViewControllerDelegate {
    @objc optional func updateChartStyle(styleParam: KLineChartStyleManager)
}

class StyleSettingViewController: UIViewController {
    
    var rowHeight: CGFloat {
        return 44
    }
    
    var rowCount: Int {
        return 4
    }
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        return view
    }()
    
    lazy var tableStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.distribution = .fillEqually
        s.spacing = 0
        s.alignment = .fill
        return s
    }()
    
    lazy var labelTheme: UILabel = {
        let view = UILabel()
        view.text = "Theme Style"
        return view
    }()
    
    var themes: [String] {
        return ["Dark", "Light"]
    }
    
    lazy var segmentTheme: UISegmentedControl = {
        let view = UISegmentedControl()
        view.insertSegment(withTitle: self.themes[0], at: 0, animated: true)
        view.insertSegment(withTitle: self.themes[1], at: 1, animated: true)
        return view
    }()
    
    lazy var labelYAxisSide: UILabel = {
        let view = UILabel()
        view.text = "YAxis Side"
        return view
    }()
    
    var yAxisSides: [String] {
        return ["Left", "Right"]
    }
    
    lazy var segmentYAxisSide: UISegmentedControl = {
        let view = UISegmentedControl()
        view.insertSegment(withTitle: self.yAxisSides[0], at: 0, animated: true)
        view.insertSegment(withTitle: self.yAxisSides[1], at: 1, animated: true)
        return view
    }()
    
    lazy var labelCandleColor: UILabel = {
        let view = UILabel()
        view.text = "Candle Color"
        return view
    }()
    
    var candleColors: [String] {
        return ["Red/Green", "Green/Red"]
    }
    
    lazy var segmentCandleColor: UISegmentedControl = {
        let view = UISegmentedControl()
        view.insertSegment(withTitle: self.candleColors[0], at: 0, animated: true)
        view.insertSegment(withTitle: self.candleColors[1], at: 1, animated: true)
        return view
    }()
    
    lazy var labelInnerYAxis: UILabel = {
        let view = UILabel()
        view.text = "Inner YAxis"
        return view
    }()
    
    lazy var switchInnerYAxis: UISwitch = {
        let view = UISwitch()
        return view
    }()
    
    var selectedTheme: Int = 0
    
    var selectedYAxisSide: Int = 1
    
    var selectedCandleColor: Int = 1
    
    var delegate: ChartStyleSettingViewControllerDelegate?

    var styleParam = KLineChartStyleManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self.segmentTheme.selectedSegmentIndex = self.themes.firstIndex(of: self.styleParam.theme) ?? self.selectedTheme
        self.segmentYAxisSide.selectedSegmentIndex = self.yAxisSides.firstIndex(of: self.styleParam.showYAxisLabel) ?? self.selectedYAxisSide
        self.segmentCandleColor.selectedSegmentIndex = self.candleColors.firstIndex(of: self.styleParam.candleColors) ?? self.selectedCandleColor
        self.switchInnerYAxis.isOn = self.styleParam.isInnerYAxis
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.saveStyle()
        
        self.delegate?.updateChartStyle?(styleParam: self.styleParam)
    }
    
    func setupUI() {
        self.view.backgroundColor = .white
        self.view.addSubview(self.scrollView)
        
        self.scrollView.addSubview(self.tableStack)
        
        let rowStack1 = UIStackView()
        rowStack1.axis = .horizontal
        rowStack1.distribution = .equalSpacing
        rowStack1.spacing = 0
        rowStack1.alignment = .center
        rowStack1.addArrangedSubview(self.labelTheme)
        rowStack1.addArrangedSubview(self.segmentTheme)
        self.tableStack.addArrangedSubview(rowStack1)
        
        let rowStack2 = UIStackView()
        rowStack2.axis = .horizontal
        rowStack2.distribution = .equalSpacing
        rowStack2.spacing = 0
        rowStack2.alignment = .center
        rowStack2.addArrangedSubview(self.labelYAxisSide)
        rowStack2.addArrangedSubview(self.segmentYAxisSide)
        self.tableStack.addArrangedSubview(rowStack2)
        
        let rowStack3 = UIStackView()
        rowStack3.axis = .horizontal
        rowStack3.distribution = .equalSpacing
        rowStack3.spacing = 0
        rowStack3.alignment = .center
        rowStack3.addArrangedSubview(self.labelCandleColor)
        rowStack3.addArrangedSubview(self.segmentCandleColor)
        self.tableStack.addArrangedSubview(rowStack3)
        
        let rowStack4 = UIStackView()
        rowStack4.axis = .horizontal
        rowStack4.distribution = .equalSpacing
        rowStack4.spacing = 0
        rowStack4.alignment = .center
        rowStack4.addArrangedSubview(self.labelInnerYAxis)
        rowStack4.addArrangedSubview(self.switchInnerYAxis)
        self.tableStack.addArrangedSubview(rowStack4)
        
        self.scrollView.snp.makeConstraints { (make) in
            make.top.bottom.right.left.equalToSuperview()
        }
        
        self.tableStack.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(CGFloat(self.rowCount) * self.rowHeight)
            make.width.equalTo(self.view.snp.width).multipliedBy(0.9)
        }
    }
}

extension StyleSettingViewController {
    fileprivate func saveStyle() {
        let theme = self.themes[self.segmentTheme.selectedSegmentIndex]
        let yAxisSide = self.yAxisSides[self.segmentYAxisSide.selectedSegmentIndex]
        let candleColors = self.candleColors[self.segmentCandleColor.selectedSegmentIndex]
        
        self.styleParam.theme = theme
        self.styleParam.candleColors = candleColors
        self.styleParam.showYAxisLabel = yAxisSide
        self.styleParam.isInnerYAxis = self.switchInnerYAxis.isOn
        
        var upcolor: UInt, downcolor: UInt
        var lineColors: [UInt]
        
        if theme == "Dark" {
            self.styleParam.backgroundColor = 0x232732
            self.styleParam.textColor = 0xcccccc
            self.styleParam.selectedTextColor = 0xcccccc
            self.styleParam.lineColor = 0x333333
            upcolor = 0x00bd9a
            downcolor = 0xff6960
            lineColors = [
                0xDDDDDD,
                0xF9EE30,
                0xF600FF
            ]
        } else {
            self.styleParam.backgroundColor = 0xffffff
            self.styleParam.textColor = 0x808080
            self.styleParam.selectedTextColor = 0xcccccc
            self.styleParam.lineColor = 0xcccccc
            upcolor = 0x1E932B
            downcolor = 0xF80D1F
            lineColors = [
                0x4E9CC1,
                0xF7A23B,
                0xF600FF
            ]
        }
        
        if self.segmentCandleColor.selectedSegmentIndex == 0 {
            self.styleParam.upColor = downcolor
            self.styleParam.downColor = upcolor
        } else {
            self.styleParam.upColor = upcolor
            self.styleParam.downColor = downcolor
        }
        
        self.styleParam.lineColors = lineColors
        
        _ = self.styleParam.saveUserData()
    }
}
