//
//  ResultViewController.swift
//  AMDFrameBufferUtility
//
//  Created by jogle on 15/6/28.
//  Copyright (c) 2015年 joglelew. All rights reserved.
//

import Foundation
import Cocoa

class ResultViewController: NSViewController, NSComboBoxDelegate {
    var connectors: [Connector] = []
    var PCIID: String = ""
    var recommendFB: String = ""
    var height: Int = 470
    var systemFBname: [String] = []
    var systemFBvalue: [String] = []
    var FBComboBox: NSComboBox?
    var FBInf: NSTextField?
    var typeBoxs: [NSComboBox] = []
    var txmitDatas: [NSTextField] = []
    var encDatas: [NSTextField] = []
    var hotpluginDatas: [NSTextField] = []
    var senseidDatas: [NSTextField] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCardInfo()
        height -= 10
        showOriginFB()
        FBComboBox!.setDelegate(self)
        var myThread = NSThread(target: self, selector: "getSystemFB", object: nil)
        myThread.start()
        
        height -= 180
        showText(connectors.count)
        showData(connectors)
        showSaveAndCloseButton()
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func showCardInfo() {
        var cardInfo = NSTextField()
        cardInfo.stringValue = "Graphic Card Info: "
        cardInfo.frame = CGRectMake(25, CGFloat(height), 140, 25)
        cardInfo.bordered = false
        cardInfo.editable = false
        cardInfo.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(cardInfo)
        height -= 20
        
        var cardId = NSTextField()
        cardId.stringValue = PCIID
        cardId.frame = CGRectMake(25, CGFloat(height), 140, 25)
        cardId.editable = false
        cardId.selectable = true
        cardId.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(cardId)
        
        var (name, fb) = getCardInf()
        recommendFB = fb
        
        var cardName = NSTextField()
        cardName.stringValue = name
        cardName.frame = CGRectMake(165, CGFloat(height), 300, 25)
        cardName.editable = false
        cardName.selectable = true
        cardName.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(cardName)
        height -= 25
        
        if (fb != "Null") {
            var recommendFB = NSTextField()
            recommendFB.stringValue = "Recommend FrameBuffer to replace: "
            recommendFB.frame = CGRectMake(25, CGFloat(height) - 5, 250, 25)
            recommendFB.bordered = false
            recommendFB.editable = false
            recommendFB.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(recommendFB)
        
            var FBName = NSTextField()
            FBName.stringValue = fb
            FBName.frame = CGRectMake(275, CGFloat(height), 100, 25)
            FBName.editable = false
            FBName.selectable = true
            FBName.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(FBName)
            height -= 25
        }
    }
    
    func showOriginFB() {
        
        var originFB = NSTextField()
        originFB.stringValue = "Origin FrameBuffer: "
        originFB.frame = CGRectMake(25, CGFloat(height - 3), 150, 25)
        originFB.bordered = false
        originFB.editable = false
        originFB.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(originFB)
        
        FBComboBox = NSComboBox()
        FBComboBox!.placeholderString = "Please wait..."
        FBComboBox!.frame = CGRectMake(175, CGFloat(height), 200, 25)
        FBComboBox!.editable = false
        FBComboBox!.selectable = true
        self.view.addSubview(FBComboBox!)
        
        FBInf = NSTextField()
        FBInf!.stringValue = ""
        FBInf!.frame = CGRectMake(25, CGFloat(height - 135), 300, 130)
        FBInf!.editable = false
        FBInf!.selectable = true
        self.view.addSubview(FBInf!)
    }
    
    func getSystemFB() {
        var task = NSTask()
        task.launchPath = "/bin/sh"
        
        // Get the path of program
        var tempDir = NSBundle.mainBundle().pathForResource("getSystemFB", ofType: "php")
        var dir = "\(tempDir)"
        
        // Delete the disgusting "Optional("...")"
        dir = dir.substringFromIndex(advance(dir.startIndex, 10))
        dir = dir.substringToIndex(advance(dir.endIndex, -2))
        task.arguments = ["-c", "php \(dir)"]
        
        // Define
        var pipe = NSPipe()
        task.standardOutput = pipe
        
        var file = NSFileHandle()
        file = pipe.fileHandleForReading
        
        task.launch()
        var data = file.readDataToEndOfFile()
        var context1 = NSString(data: data, encoding: NSUTF8StringEncoding)
        var context = "\(context1)"
        
        // Delete the disgusting "Optional("...")"
        context = context.substringFromIndex(advance(context.startIndex, 10))
        context = context.substringToIndex(advance(context.endIndex, -2))
        
        var split = context.componentsSeparatedByString("\n")
        for var i = 0; i < split.count; i++ {
            if split[i].hasSuffix("---") {
                var s = split[i].stringByReplacingOccurrencesOfString("-", withString: "")
                s = s.stringByReplacingOccurrencesOfString(".kext", withString: "")
                s = "---\(s)---"
                systemFBname.append(s)
                systemFBvalue.append("")
            }
            else if count(split[i]) > 0 {
                var s = split[i].componentsSeparatedByString("@")
                systemFBname.append(s[0])
                var n = s[0].componentsSeparatedByString("(")
                var num = "\(n[1][n[1].startIndex])".toInt()
                
                var datas = ""
                for _ in 0...num! {
                    i++
                    datas += split[i] + "\n"
                }
                systemFBvalue.append(datas)
            }
        }
        FBComboBox!.placeholderString = "Please select a framebuffer"
        FBComboBox!.addItemsWithObjectValues(systemFBname)
        for var i = 0; i < systemFBname.count; i++ {
            if systemFBname[i].hasPrefix(recommendFB) {
                FBComboBox!.selectItemAtIndex(i)
                FBInf!.stringValue = systemFBvalue[i]
                break
            }
        }
    }
    
    func getCardInf() -> (String, String) {
        // Get the path of ati.txt
        var tempDir = NSBundle.mainBundle().pathForResource("ati", ofType: "txt")
        var dir = "\(tempDir)"
        
        // Delete the disgusting "Optional("...")"
        dir = dir.substringFromIndex(advance(dir.startIndex, 10))
        dir = dir.substringToIndex(advance(dir.endIndex, -2))
        
        var content = String(contentsOfFile: dir, encoding: NSUTF8StringEncoding, error: nil)
        
        var id = PCIID.substringFromIndex(advance(PCIID.startIndex, 13))
        
        // Position card information
        var split: [String] = content!.componentsSeparatedByString("\r\n")
        var nameArray: [String] = []
        for i in split {
            if count(i) == 0 || i[i.startIndex] == "/" {
                continue
            }
            else {
                var j = ""
                if count(i) > 10 {
                    j = i.substringToIndex(advance(i.startIndex, 8))
                    j = j.substringFromIndex(advance(j.startIndex, 4))
                }
                else {
                    continue
                }
                if j == id {
                    nameArray = i.componentsSeparatedByString("\"")
                    break
                }
            }
        }
        
        if (nameArray[2].hasSuffix("Mobile")) {
            nameArray[1] += " (Mobile)"
        }
        
        while nameArray[2][nameArray[2].startIndex] == "\"" {
            nameArray[2].removeAtIndex(nameArray[2].startIndex)
        }
        while nameArray[2][nameArray[2].startIndex] == "," {
            nameArray[2].removeAtIndex(nameArray[2].startIndex)
        }
        while nameArray[2][nameArray[2].startIndex] == " " {
            nameArray[2].removeAtIndex(nameArray[2].startIndex)
        }
        if nameArray[2][nameArray[2].startIndex] == "k" {
            nameArray[2].removeAtIndex(nameArray[2].startIndex)
        }
        var i: String.Index = nameArray[2].startIndex
        while nameArray[2][i] != " " && nameArray[2][i] != "}" {
            i = advance(i, 1);
        }
        nameArray[2] = nameArray[2].substringToIndex(i)
        
        return (nameArray[1], nameArray[2])
    }
    
    func showText(count: Int) {
        var userFB = NSTextField()
        userFB.stringValue = "Framebuffer Of Your Graphics Card: "
        userFB.frame = CGRectMake(25, (CGFloat)(height), 300, 25)
        userFB.bordered = false
        userFB.editable = false
        userFB.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(userFB)
        height -= 25
        
        var typeLabel = NSTextField()
        typeLabel.stringValue = "Type"
        typeLabel.frame = CGRectMake(25, (CGFloat)(height), 100, 25)
        typeLabel.bordered = false
        typeLabel.editable = false
        typeLabel.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(typeLabel)
        
        var txmitLabel = NSTextField()
        txmitLabel.stringValue = "txmit"
        txmitLabel.frame = CGRectMake(145, (CGFloat)(height), 70, 25)
        txmitLabel.bordered = false
        txmitLabel.editable = false
        txmitLabel.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(txmitLabel)
        
        var encLabel = NSTextField()
        encLabel.stringValue = "enc"
        encLabel.frame = CGRectMake(235, (CGFloat)(height), 70, 25)
        encLabel.bordered = false
        encLabel.editable = false
        encLabel.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(encLabel)
        
        var hotpluginLabel = NSTextField()
        hotpluginLabel.stringValue = "hotplugin"
        hotpluginLabel.frame = CGRectMake(325, (CGFloat)(height), 70, 25)
        hotpluginLabel.bordered = false
        hotpluginLabel.editable = false
        hotpluginLabel.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(hotpluginLabel)
        
        var senseidLabel = NSTextField()
        senseidLabel.stringValue = "senseid"
        senseidLabel.frame = CGRectMake(415, (CGFloat)(height), 70, 25)
        senseidLabel.bordered = false
        senseidLabel.editable = false
        senseidLabel.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
        self.view.addSubview(senseidLabel)
        height -= 25
    }
    
    func showData(connectors: [Connector]) {
        for var i = 0; i < connectors.count; i++ {
            // Show type
            var typeBox = NSComboBox()
            typeBox.frame = CGRectMake(25, (CGFloat)(height), 100, 25)
            typeBox.addItemsWithObjectValues(["---", "DP", "DVI", "HDMI", "LVDS", "VGA"])
            typeBox.selectItemAtIndex(connectors[i].type)
            self.view.addSubview(typeBox)
            typeBoxs.append(typeBox)
            
            // Show txmit
            var txmitData = NSTextField()
            txmitData.stringValue = connectors[i].txmit
            txmitData.frame = CGRectMake(145, (CGFloat)(height), 70, 25)
            txmitData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(txmitData)
            txmitDatas.append(txmitData)
            
            // Show enc
            var encData = NSTextField()
            encData.stringValue = connectors[i].enc
            encData.frame = CGRectMake(235, (CGFloat)(height), 70, 25)
            encData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(encData)
            encDatas.append(encData)
            
            // Show hotplugin
            var hotpluginData = NSTextField()
            hotpluginData.stringValue = connectors[i].hotplugin
            hotpluginData.frame = CGRectMake(325, (CGFloat)(height), 70, 25)
            hotpluginData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(hotpluginData)
            hotpluginDatas.append(hotpluginData)
            
            // Show senseid
            var senseidData = NSTextField()
            senseidData.stringValue = connectors[i].hotplugin
            senseidData.frame = CGRectMake(415, (CGFloat)(height), 70, 25)
            senseidData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(senseidData)
            senseidDatas.append(senseidData)
            
            height -= 25
        }
    }
    
    func showSaveAndCloseButton() {
        var saveButton = NSButton()
        saveButton.stringValue = "Save All"
        saveButton.title = "Save All"
        saveButton.frame = CGRectMake(260, 0, 100, 25)
        saveButton.bezelStyle = NSBezelStyle.RoundedBezelStyle
        saveButton.target = self
        saveButton.action = "saveButtonPressed"
        self.view.addSubview(saveButton)
        
        var exitButton = NSButton()
        exitButton.stringValue = "Exit"
        exitButton.title = "Exit"
        exitButton.frame = CGRectMake(385, 0, 100, 25)
        exitButton.bezelStyle = NSBezelStyle.RoundedBezelStyle
        exitButton.target = self
        exitButton.action = "exitButtonPressed"
        self.view.addSubview(exitButton)
    }
    
    func saveButtonPressed() {
        var s = NSMutableString()
        s.appendString(PCIID + "\n\n")
        s.appendString("ATI Connectors Data: \n")
        s.appendString(systemFBname[FBComboBox!.indexOfSelectedItem] + "\n")
        s.appendString(systemFBvalue[FBComboBox!.indexOfSelectedItem] + "\n\n")
        s.appendString("ATI Connectors Patch: \n")
        
        s.appendString(typeBoxs[0].objectValueOfSelectedItem as! String)
        for var i = 1; i < typeBoxs.count; i++ {
            s.appendString(", ")
            s.appendString(typeBoxs[i].objectValueOfSelectedItem as! String)
        }
        s.appendString("\n")
        for var j = 0; j < typeBoxs.count; j++ {
            switch (typeBoxs[j].indexOfSelectedItem) {
                case 1: s.appendString("000400000406000000710000")
                case 2: s.appendString("040000001402000000010000")
                case 3: s.appendString("000800000402000000710000")
                case 4: s.appendString("020000004000000009010000")
                case 5: s.appendString("100000001000000000010000")
                default:s.appendString("000000000000000000000000")
            }
            s.appendString(txmitDatas[j].stringValue + encDatas[j].stringValue + hotpluginDatas[j].stringValue + senseidDatas[j].stringValue + "\n")
        }
        s.writeToFile(NSHomeDirectory() + "/Desktop/ATIData.txt", atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        
        var task = NSTask()
        task.launchPath = "/bin/sh"
        var dir = NSHomeDirectory() + "/Desktop/ATIData.txt"
        task.arguments = ["-c", "open \(dir)"]
        task.launch()
    }
    
    func exitButtonPressed() {
        exit(0)
    }
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        var i = FBComboBox!.indexOfSelectedItem
        FBInf?.stringValue = systemFBvalue[i]
    }
}