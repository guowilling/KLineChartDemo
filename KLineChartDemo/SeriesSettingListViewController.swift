
import UIKit

@objc protocol SeriesSettingListViewControllerDelegate {
    @objc optional func updateSeriesSettingParams()
}

class SeriesSettingListViewController: UIViewController {
    
    var seriesParams: [SeriesParam] = [SeriesParam]()
    
    weak var delegate: SeriesSettingListViewControllerDelegate?
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        return table
    }()
    
    lazy var tableFooterView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 100))
        return view
    }()
    
    lazy var buttonReset: UIButton = {
        let color = UIColor(hex: 0xfe9d25)
        let btn = UIButton(type: .custom)
        btn.setTitle("Reset Default", for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.layer.borderColor = color.cgColor
        btn.layer.cornerRadius = 3
        btn.layer.borderWidth = 1
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(self.buttonResetAction), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        self.tableFooterView.addSubview(self.buttonReset)
        self.tableView.tableFooterView = self.tableFooterView
        self.view.addSubview(self.tableView)
        
        self.tableView.snp.makeConstraints { (make) in
            make.top.bottom.right.left.equalToSuperview()
        }
        self.buttonReset.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 160, height: 40))
        }
        
        self.seriesParams = SeriesParamList.shared.loadUserData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.delegate?.updateSeriesSettingParams?()
    }
    
    @objc func buttonResetAction() {
        SeriesParamList.shared.resetDefault()
        self.seriesParams = SeriesParamList.shared.loadUserData()
        self.tableView.reloadData()
        let alert = UIAlertController(title: "Log", message: "Reset Default Successfully", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { (_) -> Void in }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SeriesSettingListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.seriesParams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SeriesSettingListCell?
        cell = tableView.dequeueReusableCell(withIdentifier: SeriesSettingListCell.identify) as? SeriesSettingListCell
        if cell == nil {
            cell = SeriesSettingListCell()
        }
        
        let seriesParam = self.seriesParams[indexPath.row]
        cell?.configCell(seriesParam: seriesParam)
        
        cell?.didPressButtonParamsClosure = { (cell) in
            if let indexPath = self.tableView.indexPath(for: cell) {
                let vc = SeriesSettingDetailViewController()
                vc.seriesParam = self.seriesParams[indexPath.row]
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        cell?.didPressSwitchShowClosure = { (cell, uiSwitch) in
            if let indexPath = self.tableView.indexPath(for: cell) {
                let seriesParam = self.seriesParams[indexPath.row]
                seriesParam.hidden = !uiSwitch.isOn
                _ = SeriesParamList.shared.saveUserData()
            }
        }
        return cell!
    }
}
