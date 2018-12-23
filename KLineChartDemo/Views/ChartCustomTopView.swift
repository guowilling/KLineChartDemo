
import UIKit
//import CHKLineChartKit

class ChartCustomTopView: UIView {
    
    /// 价格
    lazy var labelPrice: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0x00bd9a)
        view.font = UIFont.systemFont(ofSize: 26)
        return view
    }()
    
    /// 涨跌
    lazy var labelRise: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    /// 开盘
    lazy var labelOpen: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    /// 最高
    lazy var labelHigh: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    /// 收盘
    lazy var labelClose: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    /// 最低
    lazy var labelLow: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    /// 交易量
    lazy var labelVol: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    /// 交易额
    lazy var labelTurnover: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    /// 价格±
    lazy var labelMargin: UILabel = {
        let view = UILabel()
        view.textColor = UIColor(hex: 0xfe9d25)
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }()
    
    lazy var stackLeft: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.distribution = .fillEqually
        s.spacing = 0
        s.alignment = .fill
        return s
    }()
    
    lazy var stackRight: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.distribution = .fillEqually
        s.spacing = 0
        s.alignment = .fill
        return s
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupUI()
    }
    
    func setupUI() {
        self.addSubview(self.stackLeft)
        self.addSubview(self.stackRight)
        
        self.stackLeft.addArrangedSubview(self.labelPrice)
        
        let leftStatck1 = UIStackView()
        leftStatck1.axis = .horizontal
        leftStatck1.distribution = .fillEqually
        leftStatck1.spacing = 8
        leftStatck1.alignment = .fill
        leftStatck1.addArrangedSubview(self.labelMargin)
        leftStatck1.addArrangedSubview(self.labelRise)
        self.stackLeft.addArrangedSubview(leftStatck1)
        
        let rightStack1 = UIStackView()
        rightStack1.axis = .horizontal
        rightStack1.distribution = .fillEqually
        rightStack1.spacing = 8
        rightStack1.alignment = .fill
        rightStack1.addArrangedSubview(self.labelHigh)
        rightStack1.addArrangedSubview(self.labelOpen)
        self.stackRight.addArrangedSubview(rightStack1)
        
        let rightStack2 = UIStackView()
        rightStack2.axis = .horizontal
        rightStack2.distribution = .fillEqually
        rightStack2.spacing = 8
        rightStack2.alignment = .fill
        rightStack2.addArrangedSubview(self.labelLow)
        rightStack2.addArrangedSubview(self.labelClose)
        self.stackRight.addArrangedSubview(rightStack2)
        
        let rightStack3 = UIStackView()
        rightStack3.axis = .horizontal
        rightStack3.distribution = .fillEqually
        rightStack3.spacing = 8
        rightStack3.alignment = .fill
        rightStack3.addArrangedSubview(self.labelVol)
        rightStack3.addArrangedSubview(self.labelTurnover)
        self.stackRight.addArrangedSubview(rightStack3)
        
        self.stackLeft.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalTo(self.stackRight.snp.left)
            make.top.bottom.equalToSuperview()
        }
        
        self.stackRight.snp.makeConstraints { (make) in
            make.width.equalTo(self.stackLeft.snp.width)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }
    
    func update(data: KLineChartPoint) {
        self.labelPrice.text = "\(data.closePrice)"
        self.labelRise.text = "\(data.amplitudeRatio.toString(maxF: 2))%"
        self.labelMargin.text = "\(data.amplitude.toString(maxF: 4))"
        
        self.labelOpen.text = "开盘" + " " + "\(data.openPrice.toString(maxF: 4))"
        self.labelHigh.text = "最高" + " " + "\(data.highPrice.toString(maxF: 4))"
        self.labelLow.text = "最低" + " " + "\(data.lowPrice.toString(maxF: 4))"
        self.labelClose.text = "收盘" + " " + "\(data.closePrice.toString(maxF: 4))"
        self.labelVol.text = "交易量" + " " + "\(data.vol.toString(maxF: 2))"
        self.labelTurnover.text = "交易额" + " " + "\((data.vol * data.closePrice).toString(maxF: 2))"
    }
}
