//
//  KLineOptionButton.swift
//  SRTempDemo
//
//  Created by 郭伟林 on 2019/1/15.
//  Copyright © 2019年 BITMAIN. All rights reserved.
//

import UIKit
import SnapKit
//import SwifterSwift

// MARK: - Option UIButton

class OptionBaseButton: UIButton {
    
    var titleString: String? {
        didSet {
            setTitle(titleString, for: .normal)
            setTitle(titleString, for: .selected)
        }
    }
    
    convenience init() {
        self.init(frame: .zero)
        
        setTitleColor(UIColor.init(hex: 0x44617D), for: .normal)
        setTitleColor(UIColor.init(hex: 0x000000), for: .selected)
        titleLabel?.font = UIFont.systemFont(ofSize: 12.5)
    }
}

class KLineOptionTimeButton: OptionBaseButton {
    
    let underLine = UILabel()
    
    override var isSelected: Bool {
        didSet {
            underLine.isHidden = !isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(underLine)
        underLine.isHidden = true
        underLine.backgroundColor = UIColor.init(hex: 0x000000)
        underLine.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(2)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class KLineOptionMenuButton: OptionBaseButton {
    
    var triangleColor: UIColor!
    
    weak var menuView: KLineOptionMenuBaseView?
    
    var selectedColor = UIColor.init(hex: 0x000000)
    
    override var isSelected: Bool {
        didSet {
            triangleColor = isSelected ? selectedColor : UIColor.init(hex: 0x44617D)
            menuView?.isHidden = !isSelected
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isSelected = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
//        let color = isSelected ? UIColor.init(hex: 0x000000) : UIColor.init(hex: 0x081F32)
//        color.setFill()
//        UIRectFill(self.bounds)
        
        // 绘制三角形
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.beginPath()
        context.move(to: CGPoint(x: frame.width - 2.5, y: titleLabel!.frame.maxY ))
        context.addLine(to: CGPoint(x: frame.width - 2.5, y: titleLabel!.frame.maxY - 7.5))
        context.addLine(to: CGPoint(x: frame.width - 10, y: titleLabel!.frame.maxY))
        context.closePath()
        triangleColor.setFill()
        UIColor.clear.setStroke()
        context.drawPath(using: .fillStroke)
    }
}

// MARK: - Menu Button

class KLineOptionMenuMoreButton: UIButton {
    
    var titleString: String? {
        didSet {
            setTitle(titleString, for: .normal)
            setTitle(titleString, for: .selected)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(UIColor.init(hex: 0x44617D), for: .normal)
        setTitleColor(UIColor.init(hex: 0x000000), for: .selected)
        titleLabel?.font = UIFont.systemFont(ofSize: 12.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class KLineOptionMenuIndexButton: UIButton {
    
    var titleString: String? {
        didSet {
            setTitle(titleString, for: .normal)
            setTitle(titleString, for: .selected)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(UIColor.init(hex: 0x44617D), for: .normal)
        setTitleColor(UIColor.init(hex: 0x000000), for: .selected)
        titleLabel?.font = UIFont.systemFont(ofSize: 12.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
