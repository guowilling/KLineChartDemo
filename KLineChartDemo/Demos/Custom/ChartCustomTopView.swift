//
//  ChartCustomTopView.swift
//  KLineChartDemo
//
//  Created by 郭伟林 on 2019/7/5.
//  Copyright © 2019 SR. All rights reserved.
//

import UIKit

class ChartCustomTopView: UIView {

    private lazy var coinPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = UIColor(hexString: "#00BD9A")
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return label
    }()
    
    private lazy var legalPriceLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = UIColor(hexString: "#00BD9A")
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    
    private lazy var amplitudeLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = UIColor(hexString: "#00BD9A")
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private lazy var amplitudeRatioLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = UIColor(hexString: "#00BD9A")
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private lazy var hLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = UIColor(hexString: "#44617D")
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    private lazy var lLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = UIColor(hexString: "#44617D")
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    private lazy var vLabel: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = UIColor(hexString: "#44617D")
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor(hexString: "#001724")
        setupSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubViews() {
        addSubview(coinPriceLabel)
        addSubview(legalPriceLabel)
        addSubview(amplitudeLabel)
        addSubview(amplitudeRatioLabel)
        addSubview(hLabel)
        addSubview(lLabel)
        addSubview(vLabel)
        
        coinPriceLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(5)
            make.top.equalToSuperview().offset(5)
        }
        legalPriceLabel.snp.makeConstraints { (make) in
            make.left.equalTo(coinPriceLabel)
            make.top.equalTo(coinPriceLabel.snp.bottom)
        }
        amplitudeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(coinPriceLabel)
            make.top.equalTo(legalPriceLabel.snp.bottom)
        }
        amplitudeRatioLabel.snp.makeConstraints { (make) in
            make.left.equalTo(amplitudeLabel.snp.right).offset(5)
            make.centerY.equalTo(amplitudeLabel)
        }
        
        lLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-5)
            make.width.equalTo(100)
        }
        hLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(lLabel.snp.top).offset(-5)
            make.right.equalTo(lLabel)
            make.width.equalTo(lLabel)
        }
        vLabel.snp.makeConstraints { (make) in
            make.top.equalTo(lLabel.snp.bottom).offset(5)
            make.right.equalTo(lLabel)
            make.width.equalTo(lLabel)
        }
    }
    
    func update(point: ChartPoint) {
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
        legalPriceLabel.text = "= " + (closePrice * 6.90).formatPrice() + " " + "CNY"
        
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
        
        let textWidth = self.lLabel.text!.widthWithConstrainedHeight(height: self.lLabel.frame.height, font: self.lLabel.font) + 5
        self.lLabel.snp.updateConstraints { (make) in
            make.width.equalTo(textWidth)
        }
    }
}
