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
    var systemFBname: [String] = []
    var systemFBvalue: [String] = []
    var typeBoxs: [NSTextField] = []
    var controlFlagBoxs: [NSComboBox] = []
    var txmitDatas: [NSTextField] = []
    var encDatas: [NSTextField] = []
    var hotpluginDatas: [NSTextField] = []
    var senseidDatas: [NSTextField] = []
    var saveButton: NSButton?
    
    @IBOutlet weak var cardInfo: NSTextField!
    @IBOutlet weak var cardId: NSTextField!
    @IBOutlet weak var cardName: NSTextField!
    @IBOutlet weak var recommendFB: NSTextField!
    @IBOutlet weak var FBName: NSTextField!
    @IBOutlet weak var originFB: NSTextField!
    @IBOutlet weak var FBComboBox: NSComboBox!
    @IBOutlet weak var FBInf: NSTextField!
    @IBOutlet weak var userFB: NSTextField!
    @IBOutlet weak var typeLabel: NSTextField!
    @IBOutlet weak var controlFlagLabel: NSTextField!
    @IBOutlet weak var controller: NSTextField!
    @IBOutlet weak var idInfoStatus: NSImageView!
    @IBOutlet weak var idInfoMessage: NSTextField!
    @IBOutlet weak var opt1: NSSegmentedControl!
    @IBOutlet weak var opt2: NSSegmentedControl!
    @IBOutlet weak var opt3: NSSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCardInfo()
        showOriginFB()
        FBComboBox!.setDelegate(self)
        var myThread = NSThread(target: self, selector: "getSystemFB", object: nil)
        myThread.start()
        
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
        cardInfo.stringValue = NSLocalizedString("GRAPHIC_CARD_INFO", comment: "Graphic Card Info: ")
        
        cardId.stringValue = PCIID
        
        // Get the path of CardInfo.plist
        var tempDir = NSBundle.mainBundle().pathForResource("CardInfo", ofType: "plist")
        var dir = "\(tempDir)"
        
        // Delete the disgusting "Optional("...")"
        dir = dir.substringFromIndex(advance(dir.startIndex, 10))
        dir = dir.substringToIndex(advance(dir.endIndex, -2))
        
        var info = NSMutableDictionary(contentsOfFile: dir)!
        var id = ""
        if count(PCIID) >= 13 {
            id = PCIID.substringFromIndex(advance(PCIID.startIndex, 13))
        }
        
        if info.objectForKey(id) == nil {
            var alert = NSAlert()
            alert.messageText = NSLocalizedString("CARD_INFO_NOT_FOUND", comment: "Card Info Not Found!")
            alert.runModal()
            return
        }
        var inf: NSMutableDictionary = info.objectForKey(id) as! NSMutableDictionary

        //Split Card Name, Is Mobile, Recommend Framebuffer
        var name = inf.objectForKey("Card Name") as! String
        var isMobile = inf.objectForKey("isMobile") as! Bool
        controller.stringValue = inf.objectForKey("Controller") as! String
        if controller.stringValue < "AMD7000Controller" {
            opt1.selectedSegment = 0
            opt2.selectedSegment = 0
            opt3.selectedSegment = 0
        }
        else {
            opt1.selectedSegment = 1
            opt2.selectedSegment = 1
            opt3.selectedSegment = 1
        }
        
        if isMobile == true {
            name += NSLocalizedString("MOBILE", comment: "(Mobile)")
        }
        var fb = inf.objectForKey("Framebuffer") as! String
        
        cardName.stringValue = NSLocalizedString("CARD_NAME", comment: "Card Name: ") + name
        
        if (fb != "Null") { // fb is never "Null" now
            recommendFB.stringValue = NSLocalizedString("RECOMMEND", comment: "Recommend FrameBuffer to replace: ") + fb
        
            FBName.stringValue = fb
        }
        
        // check Info.plist in AMDxxxxController
        var kextInfo = NSMutableDictionary(contentsOfFile: "/System/Library/Extensions/\(controller.stringValue).kext/Contents/Info.plist")
        if kextInfo == nil {
            return
        }
        var IOKitPersonalities: NSMutableDictionary? = kextInfo!.objectForKey("IOKitPersonalities") as! NSMutableDictionary?
        if IOKitPersonalities == nil {
            return
        }
        var Controller: NSMutableDictionary? = IOKitPersonalities!.objectForKey("Controller") as! NSMutableDictionary?
        if Controller == nil {
            return
        }
        var IOPCIMatch: String? = Controller!.objectForKey("IOPCIMatch") as! String?
        if IOPCIMatch == nil {
            return
        }
        if IOPCIMatch!.rangeOfString(id) != nil {
            idInfoStatus.image = NSImage(named: "NSStatusAvailable");
            idInfoMessage.stringValue = NSLocalizedString("ID_IN_PLIST", comment: "Found your card ID in kext")
        }
        else {
            idInfoStatus.image = NSImage(named: "NSStatusUnavailable");
            idInfoMessage.stringValue = NSLocalizedString("ID_NOT_IN_PLIST", comment: "Not found your card ID in kext")
        }
    }
    
    func showOriginFB() {
        
        originFB.stringValue = NSLocalizedString("ORIGIN", comment: "Origin FrameBuffer: ")
        
        FBComboBox!.placeholderString = NSLocalizedString("PLEASE_WAIT", comment: "Please wait...")
        
        FBInf!.stringValue = ""
    }
    
    func getSystemFB() {
        // Copy otool
        var copyTask = NSTask()
        copyTask.launchPath = "/bin/sh"
        var otoolDir = NSBundle.mainBundle().pathForResource("otool", ofType: nil)
        var dir = "\(otoolDir)"
        
        // Delete the disgusting "Optional("...")"
        dir = dir.substringFromIndex(advance(dir.startIndex, 10))
        dir = dir.substringToIndex(advance(dir.endIndex, -2))
        
        copyTask.arguments = ["-c", "cp \(dir) /tmp/"]
        copyTask.launch()
        
        // Get System FB by using getSystemFB.php
        var task = NSTask()
        task.launchPath = "/bin/sh"
        
        // Get the path of program
        var tempDir = NSBundle.mainBundle().pathForResource("getSystemFB", ofType: "php")
        dir = "\(tempDir)"
        
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
        FBComboBox!.placeholderString = NSLocalizedString("SELECT_FB", comment: "Please select a framebuffer")
        FBComboBox!.addItemsWithObjectValues(systemFBname)
        for var i = 0; i < systemFBname.count; i++ {
            if systemFBname[i].hasPrefix(FBName.stringValue) {
                FBComboBox!.selectItemAtIndex(i)
                FBInf!.stringValue = systemFBvalue[i]
                saveButton!.enabled = true
                break
            }
        }
    }
    
    func showText(count: Int) {
        userFB.stringValue = NSLocalizedString("USER_FB", comment: "Framebuffer Of Your Graphics Card: ")
        
        typeLabel.stringValue = NSLocalizedString("TYPE", comment: "Type")
        controlFlagLabel.stringValue = NSLocalizedString("CONTROLFLAG", comment: "Control Flag")
    }
    
    func showData(connectors: [Connector]) {
        var height = 265
        for var i = 0; i < connectors.count; i++ {
            // Show type
            var typeBox = NSTextField()
            typeBox.frame = CGRectMake(323, (CGFloat)(height), 80, 25)
            typeBox.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            var reflect = ["---", "DDVI", "DP", "HDMI", "LVDS", "SDVI", "VGA"]
            typeBox.stringValue = reflect[connectors[i].type]
            typeBox.editable = false
            typeBox.selectable = true
            self.view.addSubview(typeBox)
            typeBoxs.append(typeBox)
            
            // Show Control Flag
            var controlFlagBox = NSComboBox()
            controlFlagBox.frame = CGRectMake(415, (CGFloat)(height), 125, 25)
            switch connectors[i].type {
                case 1: controlFlagBox.addItemsWithObjectValues(["0x0014(DVI-D)", "0x0214(DVI-I)", "0x0204(DVI-I)"])
                case 2: controlFlagBox.addItemsWithObjectValues(["0x0304(高清接口)", "0x0604(普通接口)"])
                case 3: controlFlagBox.addItemWithObjectValue("0x0204(默认)")
                case 4: controlFlagBox.addItemsWithObjectValues(["0x0040(普通接口)", "0x0100(高清接口)"])
                case 5: controlFlagBox.addItemsWithObjectValues(["0x0014(DVI-D)", "0x0214(DVI-I)"])
                case 6: controlFlagBox.addItemWithObjectValue("0x0010(默认)")
                default: controlFlagBox.addItemWithObjectValue("---")
            }
            controlFlagBox.selectItemAtIndex(connectors[i].controlFlag)
            self.view.addSubview(controlFlagBox)
            controlFlagBoxs.append(controlFlagBox)
            
            // Show txmit
            var txmitData = NSTextField()
            txmitData.stringValue = connectors[i].txmit
            txmitData.frame = CGRectMake(558, (CGFloat)(height+2), 40, 25)
            txmitData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(txmitData)
            txmitDatas.append(txmitData)
            
            // Show enc
            var encData = NSTextField()
            encData.stringValue = connectors[i].enc
            encData.frame = CGRectMake(613, (CGFloat)(height+2), 40, 25)
            encData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(encData)
            encDatas.append(encData)
            
            // Do Not Show hotplugin
//            var hotpluginData = NSTextField()
//            hotpluginData.stringValue = connectors[i].hotplugin
//            hotpluginData.frame = CGRectMake(613, (CGFloat)(height), 40, 25)
//            hotpluginData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
//            self.view.addSubview(hotpluginData)
//            hotpluginDatas.append(hotpluginData)
            
            // Show senseid
            var senseidData = NSTextField()
            senseidData.stringValue = connectors[i].senseid
            senseidData.frame = CGRectMake(668, (CGFloat)(height+2), 40, 25)
            senseidData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(senseidData)
            senseidDatas.append(senseidData)
            
            height -= 25
        }
    }
    
    func showSaveAndCloseButton() {
        saveButton = NSButton()
        saveButton!.stringValue = NSLocalizedString("SAVE_ALL", comment: "Save All")
        saveButton!.title = NSLocalizedString("SAVE_ALL", comment: "Save All")
        saveButton!.frame = CGRectMake(450, 5, 125, 35)
        saveButton!.bezelStyle = NSBezelStyle.RoundedBezelStyle
        saveButton!.enabled = false
        saveButton!.target = self
        saveButton!.action = "saveButtonPressed"
        self.view.addSubview(saveButton!)
        
        var exitButton = NSButton()
        exitButton.stringValue = NSLocalizedString("EXIT", comment: "Exit")
        exitButton.title = NSLocalizedString("EXIT", comment: "Exit")
        exitButton.frame = CGRectMake(600, 5, 125, 35)
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
        
        // Analyze Origin Framebuffer
        var split = systemFBvalue[FBComboBox!.indexOfSelectedItem].componentsSeparatedByString("\n")
        var originTypes = split[0].componentsSeparatedByString(", ")
        var originTypesID: [Int] = []
        for i in originTypes {
            switch i {
                case "DDVI": originTypesID.append(1)
                case "DP": originTypesID.append(2)
                case "HDMI": originTypesID.append(3)
                case "LVDS": originTypesID.append(4)
                case "SDVI": originTypesID.append(5)
                case "VGA": originTypesID.append(6)
                default: originTypesID.append(0)
            }
        }
        var originPlaceholders: [String] = []
        var originHotplugins: [String] = []
        for var j = 1; j < split.count - 1; j++ {
            var placeholder = split[j].substringWithRange(Range<String.Index>(start: advance(split[j].startIndex, 20), end: advance(split[j].startIndex, 24)))
            originPlaceholders.append(placeholder)

            var hotplugin = split[j].substringWithRange(Range<String.Index>(start: advance(split[j].startIndex, 28), end: advance(split[j].startIndex, 30)))
            originHotplugins.append(hotplugin)
        }
        
        s.appendString("ATI Connectors Patch: \n")
        
        var record: [Int] = []
        // record defines which connector data will be the postion.
        // value > 0 means ROM connector data
        // value < 0 means Origin Framebuffer connector data
        
        if opt3.selectedSegment == 1 {
            for var i = 1; i <= originTypes.count; i++ {
                record.append(-i)
            }
            var choose: [Bool] = []
            for var i = 1; i <= connectors.count; i++ {
                choose.append(false)
            }
            
            // fill in record if connector type is same
            for var j = 0; j < connectors.count; j++ {
                for var k = 0; k < originTypes.count; k++ {
                    if (originTypesID[k] == connectors[j].type) && (record[k] < 0) {
                        record[k] = j + 1
                        choose[j] = true
                        break
                    }
                }
            }
            
            // fill in record if no same connector type
            for var j = 0; j < connectors.count; j++ {
                if !choose[j] {
                    for var k = 0; k < originTypes.count; k++ {
                        if record[k] < 0 {
                            record[k] = j + 1
                            choose[j] = true
                            break
                        }
                    }
                }
            }
            
            // delete unused
            for var j = 0; j < record.count; j++ {
                if record[j] < 0 {
                    record[j] = 0
                }
            }
        }
        else{
            var i = 0
            for i = 1; i <= connectors.count; i++ {
                record.append(i)
            }
            for ; i <= originTypes.count; i++ {
                record.append(0)
            }
        }
        
        for var i = 0; i < record.count; i++ {
            if record[i] == 0 {
                s.appendString("Null")
                if i < record.count - 1 {
                    s.appendString(", ")
                }
            }
            else {
                s.appendString(typeBoxs[record[i] - 1].stringValue)
                if i < record.count - 1 {
                    s.appendString(", ")
                }
            }
        }
        s.appendString("\n")
        
        var allocateHotplugin = 0;
        for var i = 0; i < record.count; i++ {
            if (record[i] == 0) {
                s.appendString("00000000000000000000000000000000\n")
                continue
            }
            
            var j = record[i] - 1
            // Connector type and Control Flag
            switch (connectors[j].type) {
                case 1: // DDVI
                    s.appendString("04000000")
                    switch (connectors[j].controlFlag) {
                        case 0: s.appendString("14000000")
                        case 1: s.appendString("14020000")
                        case 2: s.appendString("04020000")
                        default: s.appendString("<Error> ")
                    }
                    s.appendString("0001")
                case 2: // DP
                    s.appendString("00040000")
                    switch (connectors[j].controlFlag) {
                        case 0: s.appendString("04030000")
                        case 1: s.appendString("04060000")
                        default: s.appendString("<Error> ")
                    }
                    s.appendString("0001")
                case 3: // HDMI
                    s.appendString("00080000040200000071")
                case 4: // LVDS
                    s.appendString("02000000")
                    switch (connectors[j].controlFlag) {
                        case 0: s.appendString("40000000")
                        case 1: s.appendString("00010000")
                        default: s.appendString("<Error> ")
                    }
                    s.appendString("0901")
                case 5: // SDVI
                    s.appendString("00020000")
                    switch (connectors[j].controlFlag) {
                        case 0: s.appendString("14000000")
                        case 1: s.appendString("14020000")
                        default: s.appendString("<Error> ")
                    }
                    s.appendString("0001")
                case 6: // VGA
                    s.appendString("10000000100000000001")
                default: // Null
                    s.appendString("00000000000000000000")
            }
            if opt1.selectedSegment == 0 {
                s.appendString("0000")
            }
            else {
                s.appendString(originPlaceholders[i])
            }
            
            s.appendString(txmitDatas[j].stringValue + encDatas[j].stringValue)
            if opt2.selectedSegment == 0 {
                if connectors[j].type == 4 {
                    s.appendString("00")
                }
                else {
                    s.appendString("0\(++allocateHotplugin)")
                }
            }
            else {
                s.appendString(originHotplugins[i])
            }
            
            s.appendString(senseidDatas[j].stringValue + "\n")
        }
        
        // Special Condition Warning
        if opt3.selectedSegment == 0 && connectors.count > originTypes.count {
            s.appendString("\nWarning: Number of connectors should be \(originTypes.count)\n")
        }
        if controller.stringValue == "AMD6000Controller" && connectors[0].type == 4 && encDatas[0].stringValue == "00" {
            s.appendString("\nWarning: You may need to change the enc of LVDS to 01 to avoid screen mess\n")
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
        saveButton!.enabled = true
    }
}