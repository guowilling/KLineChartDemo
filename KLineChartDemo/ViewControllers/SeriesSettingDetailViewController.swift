
import UIKit

class SeriesSettingDetailViewController: UIViewController {

    var seriesParam: SeriesParam!
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.bottom.right.left.equalToSuperview()
        }
    }
}

extension SeriesSettingDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.seriesParam.params.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SeriesSettingDetailCell?
        cell = tableView.dequeueReusableCell(withIdentifier: SeriesSettingDetailCell.identify) as? SeriesSettingDetailCell
        if cell == nil {
            cell = SeriesSettingDetailCell()
        }
        
        let param = self.seriesParam.params[indexPath.row]
        cell?.configCell(param: param)
        
        cell?.didPressStepperClosure = { (cell, stepper) in
            if let indexPath = self.tableView.indexPath(for: cell) {
                let param = self.seriesParam.params[indexPath.row]
                param.value = stepper.value
                _ = SeriesParamList.shared.saveUserData()
            }
        }
        return cell!
    }
}
