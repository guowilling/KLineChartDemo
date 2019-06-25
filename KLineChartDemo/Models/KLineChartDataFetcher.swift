
import UIKit
import SwiftyJSON


enum KLineTimeType: String {
    case min5 = "5分钟"
    case min15 = "15分钟"
    case min30 = "30分钟"
    case hour1 = "1小时"
    case hour2 = "2小时"
    case hour4 = "4小时"
    case hour6 = "6小时"
    case hour12 = "12小时"
    case day = "日线"
    case week = "周线"
    case month = "月线"
}

class KLineChartDataFetcher: NSObject {
    
    /// gdax
    let apiURL = "https://api.gdax.com/products/"
    
    static let shared: KLineChartDataFetcher = {
        let instance = KLineChartDataFetcher()
        return instance
    }()
    
    /// 获取 K 线原始数据
    ///
    /// - Parameters:
    ///   - exPair: 交易对(BTC/USDT)
    ///   - timeType: 时间周期
    ///   - completion: 完成回调
    func getKLineChartData(exPair: String, timeType: KLineTimeType, completion: @escaping (Bool, [KLineChartPoint]) -> Void) {
        // The granularity field must be one of the following values: {60, 300, 900, 3600, 21600, 86400}. Otherwise, your request will be rejected. These values correspond to timeslices representing one minute, five minutes, fifteen minutes, one hour, six hours, and one day, respectively.
        var granularity = 300
        switch timeType {
        case .min5:
            granularity = 5 * 60
        case .min15:
            granularity = 15 * 60
        case .min30:
            granularity = 30 * 60
        case .hour1:
            granularity = 1 * 60 * 60
        case .hour2:
            granularity = 2 * 60 * 60
        case .hour4:
            granularity = 4 * 60 * 60
        case .hour6:
            granularity = 6 * 60 * 60
        case .hour12:
            granularity = 12 * 60 * 60
        case .day:
            granularity = 1 * 24 * 60 * 60
        case .week:
            granularity = 7 * 24 * 60 * 60
        case .month:
            granularity = 30 * 24 * 60 * 60
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
