//
//  KLineOptionButtonsView.swift
//  SRTempDemo
//
//  Created by 郭伟林 on 2019/1/15.
//  Copyright © 2019年 BITMAIN. All rights reserved.
//

import UIKit
import SnapKit

class OptionMenuBaseView: UIView {
    convenience init() {
        self.init(frame: .zero)
        
        backgroundColor = UIColor.init(hex: 0x001724)
        isHidden = true
    }
}

class OptionMenuMoreView: OptionMenuBaseView {
    
    weak var optionMenuButton: OptionMenuButton!
    
    let buttonsTitle = ["1分钟", "5分钟", "6小时", "12小时", "周线", "月线"]
    var buttons: [OptionMenuMoreButton] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createButtons() {
        var lastBtn: OptionMenuMoreButton?
        let btnWidth = UIScreen.main.bounds.width / CGFloat(buttonsTitle.count)
        for i in 0..<buttonsTitle.count {
            let button = OptionMenuMoreButton()
            let titleString = buttonsTitle[i]
            button.titleString = titleString
            button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
            addSubview(button)
            button.snp.makeConstraints { make in
                if i == 0 {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalTo(lastBtn!.snp.right)
                }
                make.top.bottom.equalToSuperview()
                make.width.equalTo(btnWidth)
                lastBtn = button
            }
            buttons.append(button)
        }
    }
    
    @objc func buttonAction(sender: OptionMenuMoreButton) {
        optionMenuButton.titleString = sender.titleString
        optionMenuButton.setTitleColor(sender.titleColor(for: .selected), for: .normal)
        
        let optionView: ChartCustomOptionView = superview as! ChartCustomOptionView
        optionView.buttonAction(button: optionMenuButton)
    }
}

class OptionMenuIndexView: OptionMenuBaseView {
    
    weak var optionMenuButton: OptionMenuButton!
    
    let subMasterView = OptionMenuIndexSubView()
    let subAssistView = OptionMenuIndexSubView()
    
    var masterIndexChangedClosure: optionButtonActionClosure? {
        didSet { subMasterView.buttonActionClosure = masterIndexChangedClosure }
    }
    var assistIndexChangedClosure: optionButtonActionClosure? {
        didSet { subAssistView.buttonActionClosure = assistIndexChangedClosure }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subMasterView.type = .master
        addSubview(subMasterView)
        subMasterView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(30)
        }
        
        subAssistView.type = .assist
        addSubview(subAssistView)
        subAssistView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(subMasterView.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum OptionMenuIndexSubType: Int {
    case master
    case assist
}

class OptionMenuIndexSubView: UIView {
    
    let verticalLine = UIView()
    
    var titleArray: [String] = []
    
    var selectedMasterButton: OptionMenuIndexButton?
    var selectedAssistButton: OptionMenuIndexButton?
    
    var buttonActionClosure: optionButtonActionClosure?
    
    var type: OptionMenuIndexSubType! {
        didSet {
            if type == .master {
                titleArray = ["MA", "BOLL", "SAR"]
            } else {
                titleArray = ["MACD", "KDJ", "RSI"]
            }
            createLabel()
            createButtons()
        }
    }
    
    var buttons: [OptionMenuIndexButton] = []
    
    convenience init(type: OptionMenuIndexSubType) {
        self.init(frame: .zero)
        
        self.type = type
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createLabel() {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.init(hex: 0x4F9FE9)
        label.textAlignment = .center
        if type == .master {
            label.text = "主图"
        } else {
            label.text = "副图"
        }
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(50)
        }
        
        verticalLine.backgroundColor = UIColor.init(hex: 0x44617D)
        addSubview(verticalLine)
        verticalLine.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.width.equalTo(0.5)
        }
    }
    
    func createButtons() {
        var lastBtn: OptionMenuIndexButton!
        for i in 0..<titleArray.count {
            let button = OptionMenuIndexButton()
            let titleString = titleArray[i]
            button.titleString = titleString
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
            addSubview(button)
            button.snp.makeConstraints { make in
                if i == 0 {
                    make.left.equalTo(verticalLine.snp.right)
                    buttonAction(button)
                } else {
                    make.left.equalTo(lastBtn.snp.right)
                }
                make.top.bottom.equalToSuperview()
                make.width.equalTo(60)
            }
            lastBtn = button
            buttons.append(button)
        }
        
        let hideButton = OptionMenuIndexButton()
        hideButton.setTitle("隐藏", for: .normal)
        hideButton.setTitle("隐藏", for: .selected)
        if type == .master {
            hideButton.tag = 1
        } else {
            hideButton.tag = 2
        }
        hideButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        addSubview(hideButton)
        hideButton.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(60)
        }
    }
    
    @objc func buttonAction(_ button: OptionMenuIndexButton) {
        let optionView: ChartCustomOptionView? = superview?.superview as? ChartCustomOptionView
        let menuView: OptionMenuIndexView? = superview as? OptionMenuIndexView
        optionView?.buttonAction(button: (menuView?.optionMenuButton)!)
        menuView?.optionMenuButton.isSelected = true
        
        buttonActionClosure?(button.currentTitle!)
        
        if button.currentTitle! == "隐藏" {
            if button.tag == 1 {
                selectedMasterButton?.isSelected = false
            } else {
                selectedAssistButton?.isSelected = false
            }
        }
        if button.currentTitle! == "MA" || button.currentTitle! == "BOLL" {
            selectedMasterButton?.isSelected = false
            button.isSelected = true
            selectedMasterButton = button
        }
        if button.currentTitle! == "MACD" || button.currentTitle! == "KDJ" || button.currentTitle! == "RSI" {
            selectedAssistButton?.isSelected = false
            button.isSelected = true
            selectedAssistButton = button
        }
    }
}
