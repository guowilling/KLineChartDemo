
import UIKit
//import CHKLineChartKit

class ChartTableViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let times: [String] = ["5min", "15min", "1hour", "1day"]
    
    var selectedTimeIndex: [Int] = [0, 0, 0, 0, 0, 0]
    
    let exPairs: [String] = ["BTC-USD", "ETH-USD", "LTC-USD", "LTC-BTC", "ETH-BTC", "BCH-BTC"]
    
    var kLineDatas = [String: [KLineChartPoint]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for pair in self.exPairs {
            self.fetchChartDatas(symbol: pair, type: times[0])
        }
    }

    func fetchChartDatas(symbol: String, type: String) {
        KLineChartDataFetcher.shared.getKLineChartData(exPair: symbol, timeType: type) { [weak self] (success, chartPoints) in
            if success && chartPoints.count > 0 {
                self?.kLineDatas[symbol] = chartPoints
                let row = self?.exPairs.index(of: symbol)
                self?.tableView.reloadRows(at: [IndexPath(row: row!, section: 0)], with: UITableViewRowAnimation.automatic)
            }
        }
    }    
}

extension ChartTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.exPairs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChartTableViewCell.identifier) as! ChartTableViewCell
        cell.selectionStyle = .none
        let currencyType = self.exPairs[indexPath.row]
        cell.currency = currencyType
        let selectedTime = self.selectedTimeIndex[indexPath.row]
        cell.segTimes.selectedSegmentIndex = selectedTime
        if let datas = self.kLineDatas[currencyType], datas.count > 0 {
            cell.indicatorView.isHidden = true
            cell.indicatorView.stopAnimating()
            cell.reloadData(datas: datas)
        } else {
            cell.indicatorView.isHidden = false
            cell.indicatorView.startAnimating()
        }
        
        cell.updateTime = { [unowned self] (index) -> Void in
            self.selectedTimeIndex[indexPath.row] = index
            let time = self.times[index]
            self.fetchChartDatas(symbol: currencyType, type: time)
            cell.indicatorView.isHidden = false
            cell.indicatorView.startAnimating()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240
    }
}
