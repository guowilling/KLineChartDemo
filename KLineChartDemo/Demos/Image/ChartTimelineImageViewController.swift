
import UIKit
//import CHKLineChartKit

class ChartTimelineImageViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var trendImageData: [(Int, Double)] = []
    
    let imageSize: CGSize = CGSize(width: 100, height: 44)
    
    let dataSize = 24
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fetchChartDatas(symbol: "BTC-USD", type: .hour1)
    }
    
    func fetchChartDatas(symbol: String, type: ChartPointDurationType) {
        ChartPointManager.shared.getKLineChartData(exPair: symbol, timeType: type) { [weak self] (success, chartPoints) in
            if success && chartPoints.count > 0 {
                self?.trendImageData = chartPoints.map { ($0.time, $0.closePrice) }
                self?.tableView.reloadData()
            }
        }
    }
}

extension ChartTimelineImageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.trendImageData.count > 0 {
            return self.trendImageData.count / self.dataSize + 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageDemoCell")
        cell?.selectionStyle = .none
        
        let start = indexPath.row * self.dataSize
        var end = start + self.dataSize - 1
        if end >= self.trendImageData.count {
            end = self.trendImageData.count - 1
        }
        let durationDatas = self.trendImageData[start...end]
        let duration = Date.ch_getTimeByStamp(durationDatas[start].0, format: "MM-dd HH") + "~" + Date.ch_getTimeByStamp(durationDatas[end].0, format: "MM-dd HH")
        cell?.textLabel?.text = duration
        
        let imageView = cell?.contentView.viewWithTag(100) as? UIImageView
        imageView?.image = CHChartImageGenerator.share.kLineImage(
            by: Array(durationDatas),
            lineWidth: 1.5,
            backgroundColor: UIColor.white,
            lineColor: UIColor.ch_hex(0x2F8AFF),
            size: imageSize
        )
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
