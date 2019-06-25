//
//  KLineTopView.swift
//  SRTempDemo
//
//  Created by 郭伟林 on 2019/1/15.
//  Copyright © 2019年 BITMAIN. All rights reserved.
//

import UIKit

class KLineTopView: UIView {
    
    @IBOutlet weak var coinPriceLabel: UILabel!
    @IBOutlet weak var legalPriceLabel: UILabel!
    @IBOutlet weak var amplitudeLabel: UILabel!
    @IBOutlet weak var amplitudeRatioLabel: UILabel!
    
    @IBOutlet weak var hLabel: UILabel!
    @IBOutlet weak var lLabel: UILabel!
    @IBOutlet weak var vLabel: UILabel!
    
    @IBOutlet weak var lLabelWidthConstraint: NSLayoutConstraint!
    
    static func loadFromNib() -> KLineTopView {
        return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)?.first as! KLineTopView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        coinPriceLabel.text = "--"
        legalPriceLabel.text = "--"
        amplitudeLabel.text = "--"
        amplitudeRatioLabel.text = "--"
        hLabel.text = "--"
        lLabel.text = "--"
        vLabel.text = "--"
    }
    
    func update(point: KLineChartPoint) {
        let openPrice = point.openPrice
        let closePrice = point.closePrice
        let highPrice = point.highPrice
        let lowPrice = point.lowPrice
        let volume = point.vol
        let amplitude = closePrice - openPrice
        let amplitudeRatio = amplitude / openPrice
        
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
            amplitudeLabel.textColor = UIColor(hexString: "0x00bd9a")
            amplitudeRatioLabel.textColor = UIColor(hexString: "0x00bd9a")
            self.amplitudeLabel.text = "+\(amplitude.formatPrice())"
            self.amplitudeRatioLabel.text = "+\(String(format: "%.2f", amplitudeRatio * 100))%"
        } else {
            coinPriceLabel.textColor = UIColor(hexString: "0xff6960")
            legalPriceLabel.textColor = UIColor(hexString: "0xff6960")
            amplitudeLabel.textColor = UIColor(hexString: "0xff6960")
            amplitudeRatioLabel.textColor = UIColor(hexString: "0xff6960")
            self.amplitudeLabel.text = "\(amplitude.formatPrice())"
            self.amplitudeRatioLabel.text = "\(String(format: "%.2f", amplitudeRatio * 100))%"
        }
        if abs(amplitudeRatio * 100 * 100) < 0.1 {
            coinPriceLabel.textColor = UIColor(hexString: "#5E6269")
            legalPriceLabel.textColor = UIColor(hexString: "#5E6269")
            amplitudeLabel.textColor = UIColor(hexString: "#5E6269")
            amplitudeRatioLabel.textColor = UIColor(hexString: "#5E6269")
        }
        
        self.hLabel.text = "24H最高:" + " " + "\(highPrice.formatPrice())"
        self.lLabel.text = "24H最低:" + " " + "\(lowPrice.formatPrice())"
        self.vLabel.text = "24H量:" + " " + volume.formatAmount()
        
        self.lLabelWidthConstraint.constant = self.lLabel.text!.widthWithConstrainedHeight(height: self.lLabel.frame.height, font: self.lLabel.font) + 5
    }
}
