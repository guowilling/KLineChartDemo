
import UIKit
import SnapKit

class SeriesSettingListCell: UITableViewCell {
    
    static let identify: String = "SeriesSettingListCell"
    
    var didPressButtonParamsClosure: ((_ cell: SeriesSettingListCell) -> Void)?
    
    var didPressSwitchShowClosure: ((_ cell: SeriesSettingListCell, _ uiSwitch: UISwitch) -> Void)?
    
    lazy var labelTitle: UILabel = {
        let v = UILabel()
        v.textColor = .black
        return v
    }()
    
    lazy var switchShow: UISwitch = {
        let v = UISwitch()
        v.addTarget(self, action: #selector(self.switchShowAction), for: .touchUpInside)
        return v
    }()
    
    lazy var buttonParams: UIButton = {
        let v = UIButton(type: .custom)
        v.setTitle("Params", for: .normal)
        v.setTitleColor(UIColor(hex: 0xfe9d25), for: .normal)
        v.addTarget(self, action: #selector(self.buttonParamsAction), for: .touchUpInside)
        return v
    }()
    
    init() {
        super.init(style: .default, reuseIdentifier: SeriesSettingListCell.identify)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupUI()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupUI() {
        self.contentView.addSubview(self.labelTitle)
        self.contentView.addSubview(self.buttonParams)
        self.contentView.addSubview(self.switchShow)
        
        self.labelTitle.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(15)
        }
        
        self.switchShow.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(15)
        }
        
        self.buttonParams.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(self.switchShow.snp.left).offset(-15)
        }
    }
    
    func configCell(seriesParam: SeriesParam) {
        self.labelTitle.text = seriesParam.name
        self.switchShow.isOn = !seriesParam.hidden
        self.selectionStyle = .none
    }
    
    @objc func buttonParamsAction() {
        self.didPressButtonParamsClosure?(self)
    }
    
    @objc func switchShowAction() {
        self.didPressSwitchShowClosure?(self, self.switchShow)
    }
}
