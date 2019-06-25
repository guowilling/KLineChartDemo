//
//  KLineTopLandscapeView.swift
//  MatrixExchange
//
//  Created by 郭伟林 on 2019/6/3.
//  Copyright © 2019 Matrix. All rights reserved.
//

import UIKit

class KLineTopLandscapeView: UIView {
    
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var coinPriceLabel: UILabel!
    @IBOutlet weak var amplitudeRatioLabel: UILabel!
    @IBOutlet weak var legalPriceLabel: UILabel!
    
    @IBOutlet weak var hLabel: UILabel!
    @IBOutlet weak var lLabel: UILabel!
    @IBOutlet weak var vLabel: UILabel!
    
    static func loadFromNib() -> KLineTopLandscapeView {
        return Bundle.main.loadNibNamed(String(describing: KLineTopLandscapeView.self), owner: nil, options: nil)?.first as! KLineTopLandscapeView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        symbolLabel.text = "--"
        coinPriceLabel.text = "--"
        legalPriceLabel.text = "--"
        amplitudeRatioLabel.text = "--"
        hLabel.text = "--"
        lLabel.text = "--"
        vLabel.text = "--"
        
        if BM_SCREEN_W == 375 {
            symbolLabel.font = UIFont(name: symbolLabel.font.fontName, size: symbolLabel.font.pointSize - 2)
            coinPriceLabel.font = UIFont(name: coinPriceLabel.font.fontName, size: coinPriceLabel.font.pointSize - 2)
            legalPriceLabel.font = UIFont(name: legalPriceLabel.font.fontName, size: legalPriceLabel.font.pointSize - 1)
            amplitudeRatioLabel.font = UIFont(name: amplitudeRatioLabel.font.fontName, size: amplitudeRatioLabel.font.pointSize - 1)
            hLabel.font = UIFont(name: hLabel.font.fontName, size: hLabel.font.pointSize - 1)
            lLabel.font = UIFont(name: lLabel.font.fontName, size: lLabel.font.pointSize - 1)
            vLabel.font = UIFont(name: vLabel.font.fontName, size: vLabel.font.pointSize - 1)
        }
    }
    
    func update(point: KLineChartPoint) {
        let openPrice = point.openPrice
        let closePrice = point.closePrice
        let highPrice = point.highPrice
        let lowPrice = point.lowPrice
        let volume = point.vol
        let amplitude = closePrice - openPrice
        let amplitudeRatio = amplitude / openPrice
        
        symbolLabel.text = point.symbol
        UIView.animate(withDuration: 0.5, animations: {
            self.coinPriceLabel.alpha = 0.5
        }) { (_) in
            UIView.animate(withDuration: 1.0) {
                self.coinPriceLabel.alpha = 1.0
            }
        }
        coinPriceLabel.text = closePrice.formatPrice()
//        legalPriceLabel.text = "= " + (priceChange.busdt * ExchangeDataManager.shared.currentRate.rate).formatPrice() + " " + ExchangeDataManager.shared.currentRate.eName
        
        if amplitude > 0 {
            coinPriceLabel.textColor = UIColor(hexString: "0x00bd9a")
            legalPriceLabel.textColor = UIColor(hexString: "0x00bd9a")
            amplitudeRatioLabel.textColor = UIColor(hexString: "0x00bd9a")
            self.amplitudeRatioLabel.text = "+\(String(format: "%.2f", amplitudeRatio * 100))%"
        } else {
            coinPriceLabel.textColor = UIColor(hexString: "0xff6960")
            legalPriceLabel.textColor = UIColor(hexString: "0xff6960")
            amplitudeRatioLabel.textColor = UIColor(hexString: "0xff6960")
            self.amplitudeRatioLabel.text = "\(String(format: "%.2f", amplitudeRatio * 100))%"
        }
        if abs(amplitudeRatio * 100 * 100) < 0.1 {
            coinPriceLabel.textColor = UIColor(hexString: "#5E6269")
            legalPriceLabel.textColor = UIColor(hexString: "#5E6269")
            amplitudeRatioLabel.textColor = UIColor(hexString: "#5E6269")
        }
        
        hLabel.text = "24H最高:" + " " + "\(highPrice.formatPrice())"
        lLabel.text = "24H最低:" + " " + "\(lowPrice.formatPrice())"
        vLabel.text = "24H量:" + " " + volume.formatAmount()
    }
    
}
