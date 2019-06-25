//
//  KLineOptionView.swift
//  SRTempDemo
//
//  Created by 郭伟林 on 2019/1/15.
//  Copyright © 2019年 BITMAIN. All rights reserved.
//

import UIKit
import SnapKit

public typealias KLineButtonActionClosure = ((String) -> Void)

public class KLineOptionView: UIView {
    
    var buttonsTitleArray = ["分时", "15分钟", "1小时", "4小时", "日线", "更多", "指标"]
    
    let menuMoreView = KLineOptionMenuMoreView()
    let menuIndexView = KLineOptionMenuIndexView()
    
    weak var moreMenuButton: KLineOptionMenuButton!
    weak var indexMenuButton: KLineOptionMenuButton!
   
    var selectedTimeButton: KLineOptionBaseButton?
    var selectedMenuButton: KLineOptionMenuButton?
    
    var timeChangedClosure: KLineButtonActionClosure?
    
    var masterIndexChangedClosure: KLineButtonActionClosure? {
        didSet { menuIndexView.masterIndexChangedClosure = masterIndexChangedClosure }
    }
    var assistIndexChangedClosure: KLineButtonActionClosure? {
        didSet { menuIndexView.assistIndexChangedClosure = assistIndexChangedClosure }
    }
    
    var buttons: [KLineOptionBaseButton] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(menuMoreView)
        menuMoreView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
            make.height.equalTo(44)
        }
        
        addSubview(menuIndexView)
        menuIndexView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.snp.bottom)
            make.height.equalTo(44 * 2 + 10)
        }
        
        createButtons()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createButtons() {
        var lastBtn: KLineOptionBaseButton?
        for i in 0..<buttonsTitleArray.count {
            var button: KLineOptionBaseButton
            if i < buttonsTitleArray.count - 2 {
                button = KLineOptionTimeButton()
            } else {
                button = KLineOptionMenuButton()
                if i == buttonsTitleArray.count - 1 {
                    indexMenuButton = button as? KLineOptionMenuButton
                    indexMenuButton.menuView = menuIndexView
                    menuIndexView.optionMenuButton = indexMenuButton
                } else {
                    moreMenuButton = button as? KLineOptionMenuButton
                    moreMenuButton.menuView = menuMoreView
                    menuMoreView.optionMenuButton = moreMenuButton
                }
            }
            button.titleString = buttonsTitleArray[i]
            if button.titleString == "1小时" {
                button.isSelected = true
                selectedTimeButton = button
            }
            button.addTarget(self, action: #selector(buttonAction(button:)), for: .touchUpInside)
            addSubview(button)
            button.snp.makeConstraints { make in
                if i == 0 {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalTo(lastBtn!.snp.right)
                }
                make.top.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(1.0 / Double(buttonsTitleArray.count))
                make.height.equalToSuperview()
            }
            lastBtn = button
            buttons.append(button)
        }
    }
    
    @objc func buttonAction(button: KLineOptionBaseButton) {
        if button.isKind(of: KLineOptionMenuButton.self) {
            if button == selectedMenuButton {
                selectedMenuButton!.isSelected = !selectedMenuButton!.isSelected
            } else {
                selectedMenuButton?.isSelected = false
                button.isSelected = true
                selectedMenuButton = button as? KLineOptionMenuButton
            }
            if button == moreMenuButton {
                if button.titleString != "更多" && !selectedMenuButton!.isSelected {
                    selectedTimeButton?.isSelected = false
                    timeChangedClosure?(button.titleString!)
                }
            }
        } else {
            selectedMenuButton?.isSelected = false
            
            moreMenuButton.titleString = "更多"
            moreMenuButton.setTitleColor(UIColor.init(hex: 0x44617D), for: .normal)
            
            selectedTimeButton?.isSelected = false
            button.isSelected = true
            selectedTimeButton = button
            
            timeChangedClosure?(button.titleString!)
        }
    }
    
    func setThemeColor(hex: UInt) {
        moreMenuButton.backgroundColor = UIColor(hex: hex)
        menuMoreView.backgroundColor = UIColor(hex: hex)
        
        indexMenuButton.backgroundColor = UIColor(hex: hex)
        menuIndexView.backgroundColor = UIColor(hex: hex)
        
        if hex == 0xffffff {
            for btn in buttons {
                btn.setTitleColor(UIColor.init(hex: 0x000000), for: .selected)
                if let btn = btn as? KLineOptionTimeButton {
                    btn.underLine.backgroundColor = UIColor.init(hex: 0x000000)
                }
                if let btn = btn as? KLineOptionMenuButton {
                    btn.selectedColor = UIColor.init(hex: 0x000000)
                }
            }
            for btn in menuMoreView.buttons {
                btn.setTitleColor(UIColor.init(hex: 0x000000), for: .selected)
            }
            for btn in menuIndexView.subMasterView.buttons {
                btn.setTitleColor(UIColor.init(hex: 0x000000), for: .selected)
            }
            for btn in menuIndexView.subAssistView.buttons {
                btn.setTitleColor(UIColor.init(hex: 0x000000), for: .selected)
            }
        } else {
            for btn in buttons {
                btn.setTitleColor(UIColor.init(hex: 0xffffff), for: .selected)
                if let btn = btn as? KLineOptionTimeButton {
                    btn.underLine.backgroundColor = UIColor.init(hex: 0xffffff)
                }
                if let btn = btn as? KLineOptionMenuButton {
                    btn.selectedColor = UIColor.init(hex: 0xffffff)
                }
            }
            for btn in menuMoreView.buttons {
                btn.setTitleColor(UIColor.init(hex: 0xffffff), for: .selected)
            }
            for btn in menuIndexView.subMasterView.buttons {
                btn.setTitleColor(UIColor.init(hex: 0xffffff), for: .selected)
            }
            for btn in menuIndexView.subAssistView.buttons {
                btn.setTitleColor(UIColor.init(hex: 0xffffff), for: .selected)
            }
        }
    }
}

extension KLineOptionView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view != nil {
            return view
        }
        var targetView: UIView? = self
        var searchView: UIView? = searchReponseView(targetView!, point)
        targetView = nil
        while searchView != nil {
            targetView = searchView
            searchView = searchReponseView(targetView!, point)
            if targetView!.isKind(of: UIButton.self) {
                return targetView
            }
        }
        return targetView
    }
    
    func searchReponseView(_ superView: UIView, _ point: CGPoint) -> UIView? {
        for subview in superView.subviews {
            let convertedPoint = subview.convert(point, from: self)
            if subview.bounds.contains(convertedPoint) && subview.isHidden == false {
                return subview
            }
        }
        return nil
    }
}
