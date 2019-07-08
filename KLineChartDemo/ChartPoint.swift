
import UIKit
import SwiftyJSON

class ChartPoint: NSObject, Codable {
    
    var time: Int = 0
    var lowPrice: Double = 0
    var highPrice: Double = 0
    var openPrice: Double = 0
    var closePrice: Double = 0
    var vol: Double = 0
    
    var symbol: String = ""
    var platfom: String = ""
    var rise: Double = 0
    var timeType: String = ""
    var amplitude: Double = 0
    var amplitudeRatio: Double = 0
    
    convenience init(json: [JSON]) {
        self.init()
        
        self.time = json[0].intValue
        self.highPrice = json[2].doubleValue
        self.lowPrice = json[1].doubleValue
        self.openPrice = json[3].doubleValue
        self.closePrice = json[4].doubleValue
        self.vol = json[5].doubleValue
        
        if self.openPrice > 0 {
            self.amplitude = self.closePrice - self.openPrice
            self.amplitudeRatio = self.amplitude / self.openPrice * 100
        }
    }
}
