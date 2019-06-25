
import UIKit
//import CHKLineChartKit

class ChartImageViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var kLineChartDatas = [(Int, Double)]()
    
    let imageSize: CGSize = CGSize(width: 80, height: 40)
    
    let dataSize = 40
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fetchChartDatas(symbol: "BTC-USD", type: .min15)
    }
    
    func fetchChartDatas(symbol: String, type: KLineTimeType) {
        KLineChartDataFetcher.shared.getKLineChartData(exPair: symbol, timeType: type) { [weak self] (success, chartPoints) in
            if success && chartPoints.count > 0 {
                self?.kLineChartDatas = chartPoints.map { ($0.time, $0.closePrice) }
                self?.tableView.reloadData()
            }
        }
    }
}

extension ChartImageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.kLineChartDatas.count > 0 {
            return self.kLineChartDatas.count / self.dataSize + 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoCell")
        cell?.selectionStyle = .none
    
        let start = indexPath.row * self.dataSize
        var end = start + self.dataSize - 1
        if end >= self.kLineChartDatas.count {
            end = self.kLineChartDatas.count - 1
        }
        let durationDatas = self.kLineChartDatas[start...end]
        let duration = Date.ch_getTimeByStamp(durationDatas[start].0, format: "HH:mm") + "~" + Date.ch_getTimeByStamp(durationDatas[end].0, format: "HH:mm")
        cell?.textLabel?.text = duration
    
        let imageView = cell?.contentView.viewWithTag(100) as? UIImageView
        imageView?.image = CHChartImageGenerator.share.kLineImage(by: Array(durationDatas),
                                                                  lineWidth: 1,
                                                                  backgroundColor: UIColor.white,
                                                                  lineColor: UIColor.ch_hex(0xA4AAB3),
                                                                  size: imageSize)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
