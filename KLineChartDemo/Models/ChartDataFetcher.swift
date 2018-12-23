
import UIKit
import SwiftyJSON

class ChartDataFetcher: NSObject {
    
    /// gdax
    let apiURL = "https://api.gdax.com/products/"
    
    static let shared: ChartDataFetcher = {
        let instance = ChartDataFetcher()
        return instance
    }()
    
    /// 获取 K 线原始数据
    ///
    /// - Parameters:
    ///   - exPair: 交易对(BTC/USDT)
    ///   - timeType: 时间周期
    ///   - completion: 完成回调
    func getKLineChartData(exPair: String, timeType: String, completion: @escaping (Bool, [KLineChartPoint]) -> Void) {
        // The granularity field must be one of the following values: {60, 300, 900, 3600, 21600, 86400}. Otherwise, your request will be rejected. These values correspond to timeslices representing one minute, five minutes, fifteen minutes, one hour, six hours, and one day, respectively.
        var granularity = 300
        switch timeType {
        case "5min":
            granularity = 5 * 60
        case "15min":
            granularity = 15 * 60
        case "30min":
            granularity = 30 * 60
        case "1hour":
            granularity = 1 * 60 * 60
        case "2hour":
            granularity = 2 * 60 * 60
        case "4hour":
            granularity = 4 * 60 * 60
        case "6hour":
            granularity = 6 * 60 * 60
        case "8hour":
            granularity = 8 * 60 * 60
        case "1day":
            granularity = 1 * 24 * 60 * 60
        case "3day":
            granularity = 3 * 24 * 60 * 60
        case "1周":
            granularity = 7 * 24 * 60 * 60
        case "1月":
            granularity = 30 * 24 * 60 * 60
        default:
            granularity = 300
        }
        
        // https://api.gdax.com/products/BTC-USD/candles?granularity=300
        let url = URL(string: self.apiURL + exPair + "/candles?granularity=\(granularity)")
        let task = URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            DispatchQueue.main.async {
                guard error == nil, let data = data else {
                    print(error!)
                    completion(false, [])
                    return
                }
                var chartPoints = [KLineChartPoint]()
                do {
                    let json = try JSON(data: data)
                    let pointDatas = json.arrayValue
                    for pointData in pointDatas {
                        let chartPoint = KLineChartPoint(json: pointData.arrayValue)
                        chartPoints.append(chartPoint)
                    }
                    chartPoints.reverse()
                    completion(true, chartPoints)
                } catch _ {
                    completion(false, chartPoints)
                }
            }
        })
        task.resume()
    }
}
