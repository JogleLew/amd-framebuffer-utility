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
    var mode: Int = 0;
    var connectors: [Connector] = []
    var fbOriginName: String = ""
    var PCIID: String = ""
    var systemFBname: [String] = []
    var systemFBvalue: [String] = []
    var typeBoxs: [NSTextField] = []
    var controlFlagBoxs: [NSPopUpButton] = []
    var txmitDatas: [NSTextField] = []
    var encDatas: [NSTextField] = []
    var hotpluginDatas: [NSTextField] = []
    var senseidDatas: [NSTextField] = []
    var checkBoxes: [NSButton] = []
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
    @IBOutlet weak var offlineSign: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSaveAndCloseButton()
        showCardInfo()
        showOriginFB()
        FBComboBox!.setDelegate(self)
        if fbOriginName == "" {
            loadOfflineFB()
        }
        else {
            let myThread = NSThread(target: self, selector: #selector(ResultViewController.getSystemFB), object: nil)
            myThread.start()
        }
        
        showText(connectors.count)
        showData(connectors)
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
        let tempDir = NSBundle.mainBundle().pathForResource("CardInfo", ofType: "plist")!
        let dir = "\(tempDir)"
        
        let info = NSMutableDictionary(contentsOfFile: dir)!
        var id = ""
        if PCIID.characters.count >= 13 {
            id = PCIID.substringFromIndex(PCIID.startIndex.advancedBy(13))
            #if DEUBUG
                println("PCI ID: 1002-\(PCIID)")
            #endif
        }
        
        if info.objectForKey(id) == nil {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("CARD_INFO_NOT_FOUND", comment: "Card Info Not Found!")
            alert.runModal()
            return
        }
        let inf: NSMutableDictionary = info.objectForKey(id) as! NSMutableDictionary

        //Split Card Name, Is Mobile, Recommend Framebuffer
        var name = inf.objectForKey("Card Name") as! String
        let isMobile = inf.objectForKey("isMobile") as! Bool
        controller.stringValue = inf.objectForKey("Controller") as! String
        if controller.stringValue < "AMD7000Controller" {
            opt1.selectedSegment = 0
            opt2.selectedSegment = 0
            opt3.selectedSegment = 1
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
        #if DEUBUG
            println("Name: \(name)")
            println("Framebuffer: \(fb)")
        #endif
        
        // check Info.plist in AMDxxxxController
        let kextInfo = NSMutableDictionary(contentsOfFile: "/Volumes/\(fbOriginName)/System/Library/Extensions/\(controller.stringValue).kext/Contents/Info.plist")
        if kextInfo == nil {
            return
        }
        let IOKitPersonalities: NSMutableDictionary? = kextInfo!.objectForKey("IOKitPersonalities") as! NSMutableDictionary?
        if IOKitPersonalities == nil {
            return
        }
        let Controller: NSMutableDictionary? = IOKitPersonalities!.objectForKey("Controller") as! NSMutableDictionary?
        if Controller == nil {
            return
        }
        let IOPCIMatch: String? = Controller!.objectForKey("IOPCIMatch") as! String?
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
        #if DEUBUG
            println(idInfoMessage.stringValue)
        #endif
    }
    
    func showOriginFB() {
        
        originFB.stringValue = NSLocalizedString("ORIGIN", comment: "Origin FrameBuffer: ")
        
        FBComboBox!.placeholderString = NSLocalizedString("PLEASE_WAIT", comment: "Please wait...")
        
        FBInf!.stringValue = ""
    }
    
    func getSystemFB() {
        // Get otool path
        let otoolDir = NSBundle.mainBundle().pathForResource("otool", ofType: nil)!
        var otooldir = "\(otoolDir)"

        otooldir = otooldir.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
        
        // Get System FB by using getSystemFB
        let task = NSTask()
        task.launchPath = "/bin/sh"
        
        // Get the path of program
        var tempDir = "";
        if mode == 0 {
            tempDir = NSBundle.mainBundle().pathForResource("getSystemFB16", ofType: nil)!
        }
        else if mode == 1 {
            tempDir = NSBundle.mainBundle().pathForResource("getSystemFB24", ofType: nil)!
        }
        var dir = "\(tempDir)"

        dir = dir.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
        let fbOriginNameHandleBlank = fbOriginName.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
        task.arguments = ["-c", "\(dir) \(fbOriginNameHandleBlank) \(otooldir)"]
        
        // Define
        let pipe = NSPipe()
        task.standardOutput = pipe
        
        var file = NSFileHandle()
        file = pipe.fileHandleForReading
        
        task.launch()
        let data = file.readDataToEndOfFile()
        let context1 = NSString(data: data, encoding: NSUTF8StringEncoding)!
        let context = "\(context1)"
        
        var split = context.componentsSeparatedByString("\n")
        
        var i = 0
        while i < split.count {
            if split[i].hasSuffix("---") {
                var s = split[i].stringByReplacingOccurrencesOfString("-", withString: "")
                s = s.stringByReplacingOccurrencesOfString(".kext", withString: "")
                s = "---\(s)---"
                systemFBname.append(s)
                systemFBvalue.append("")
            }
            else if split[i].characters.count > 0 {
                var s = split[i].componentsSeparatedByString("@")
                systemFBname.append(s[0])
                var n = s[0].componentsSeparatedByString("(")
                let num = Int("\(n[1][n[1].startIndex])")
                
                var datas = ""
                for _ in 0...num! {
                    i += 1
                    datas += split[i] + "\n"
                }
                systemFBvalue.append(datas)
            }
            i += 1
        }
        FBComboBox!.placeholderString = NSLocalizedString("SELECT_FB", comment: "Please select a framebuffer")
        FBComboBox!.addItemsWithObjectValues(systemFBname)
        for j in 0 ..< systemFBname.count {
            if systemFBname[j].lowercaseString.hasPrefix(FBName.stringValue.lowercaseString) {
                FBComboBox!.selectItemAtIndex(j)
                FBInf!.stringValue = systemFBvalue[j]
                saveButton!.enabled = true
                break
            }
        }
        
//        // Store Framebuffer
//        let dic: NSMutableDictionary = NSMutableDictionary();
//        var set: NSMutableDictionary = NSMutableDictionary();
//        for i in 0 ..< systemFBname.count {
//            if systemFBname[i].hasPrefix("---") {
//                set = NSMutableDictionary()
//                dic.setObject(set, forKey: systemFBname[i])
//                continue
//            }
//            set.setObject(systemFBvalue[i], forKey: systemFBname[i])
//        }
//        dic.writeToFile("/Users/jogle/Desktop/offline.plist", atomically: true)
    }
    
    func loadOfflineFB() {
        var tempDir = ""
        if mode == 1 {
            tempDir = NSBundle.mainBundle().pathForResource("OfflineFB24", ofType: "plist")!
        }
        else if mode == 0 {
            tempDir = NSBundle.mainBundle().pathForResource("OfflineFB16", ofType: "plist")!
        }
        let dir = "\(tempDir)"
        print(dir)
        
        let info = NSMutableDictionary(contentsOfFile: dir)!
        for (key, value) in info {
            let name = "\(key)"
            
            systemFBname.append(name)
            systemFBvalue.append("")
            let set: NSMutableDictionary = value as! NSMutableDictionary
            for (k, v) in set {
                let name = "\(k)"
                let value = "\(v)"
                systemFBname.append(name)
                systemFBvalue.append(value)
            }
        }
        
        FBComboBox!.addItemsWithObjectValues(systemFBname)
        for i in 0 ..< systemFBname.count {
            if systemFBname[i].hasPrefix(FBName.stringValue) {
                FBComboBox!.selectItemAtIndex(i)
                FBInf!.stringValue = systemFBvalue[i]
                saveButton!.enabled = true
                break
            }
        }
        
        offlineSign.hidden = false
    }
    
    func showText(count: Int) {
        userFB.stringValue = NSLocalizedString("USER_FB", comment: "Framebuffer Of Your Graphics Card: ")
        
        typeLabel.stringValue = NSLocalizedString("TYPE", comment: "Type")
        controlFlagLabel.stringValue = NSLocalizedString("CONTROLFLAG", comment: "Control Flag")
    }
    
    func showData(connectors: [Connector]) {
        var height = 265
        for i in 0 ..< connectors.count {
            // Show choose button
            let checkBox = NSButton()
            checkBox.title = ""
            checkBox.setButtonType(NSButtonType.SwitchButton)
            checkBox.state = NSOnState
            checkBox.frame = CGRectMake(480, (CGFloat)(height+1), 25, 25)
            self.view.addSubview(checkBox)
            checkBoxes.append(checkBox)
            
            // Show type
            let typeBox = NSTextField()
            typeBox.frame = CGRectMake(513, (CGFloat)(height+2), 60, 25)
            typeBox.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            var reflect = ["---", "DDVI", "DP", "HDMI", "LVDS", "SDVI", "VGA"]
            typeBox.stringValue = reflect[connectors[i].type]
            typeBox.editable = false
            typeBox.selectable = true
            self.view.addSubview(typeBox)
            typeBoxs.append(typeBox)
            
            // Show Control Flag
            let controlFlagBox = NSPopUpButton()
            // controlFlagBox.editable = false
            // controlFlagBox.selectable = true
            controlFlagBox.frame = CGRectMake(590, (CGFloat)(height), 175, 25)
            switch connectors[i].type {
                case 1: controlFlagBox.addItemsWithTitles(["0x0014(DVI-D)", "0x0214(DVI-I)", "0x0204(DVI-I)"])
                case 2: controlFlagBox.addItemsWithTitles(["0x0304(" + NSLocalizedString("HIGH_RESOLUTION", comment: "High Resolution") + ")", "0x0604(" + NSLocalizedString("NORMAL", comment: "Normal") + ")"])
                case 3: controlFlagBox.addItemWithTitle("0x0204(" + NSLocalizedString("DEFAULT", comment: "Default") + ")")
                case 4: controlFlagBox.addItemsWithTitles(["0x0040(" + NSLocalizedString("NORMAL", comment: "Normal") + ")", "0x0100(" + NSLocalizedString("HIGH_RESOLUTION", comment: "High Resolution") + ")"])
                case 5: controlFlagBox.addItemsWithTitles(["0x0014(DVI-D)", "0x0214(DVI-I)"])
                case 6: controlFlagBox.addItemWithTitle("0x0010(" + NSLocalizedString("DEFAULT", comment: "Default") + ")")
                default: controlFlagBox.addItemWithTitle("---")
            }
            controlFlagBox.selectItemAtIndex(connectors[i].controlFlag)
            self.view.addSubview(controlFlagBox)
            controlFlagBoxs.append(controlFlagBox)
            
            // Show txmit
            let txmitData = NSTextField()
            txmitData.stringValue = connectors[i].txmit
            txmitData.frame = CGRectMake(783, (CGFloat)(height+2), 40, 25)
            txmitData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(txmitData)
            txmitDatas.append(txmitData)
            
            // Show enc
            let encData = NSTextField()
            encData.stringValue = connectors[i].enc
            encData.frame = CGRectMake(838, (CGFloat)(height+2), 40, 25)
            encData.bezelStyle = NSTextFieldBezelStyle.RoundedBezel
            self.view.addSubview(encData)
            encDatas.append(encData)
            
            // Show senseid
            let senseidData = NSTextField()
            senseidData.stringValue = connectors[i].senseid
            senseidData.frame = CGRectMake(893, (CGFloat)(height+2), 40, 25)
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
        saveButton!.frame = CGRectMake(575, 5, 125, 35)
        saveButton!.bezelStyle = NSBezelStyle.RoundedBezelStyle
        saveButton!.enabled = false
        saveButton!.target = self
        saveButton!.action = #selector(ResultViewController.saveButtonPressed)
        self.view.addSubview(saveButton!)
        
        let exitButton = NSButton()
        exitButton.stringValue = NSLocalizedString("EXIT", comment: "Exit")
        exitButton.title = NSLocalizedString("EXIT", comment: "Exit")
        exitButton.frame = CGRectMake(725, 5, 125, 35)
        exitButton.bezelStyle = NSBezelStyle.RoundedBezelStyle
        exitButton.target = self
        exitButton.action = #selector(ResultViewController.exitButtonPressed)
        self.view.addSubview(exitButton)
    }
    
    func saveButtonPressed() {
        var connectors: [Connector] = []
        var typeBoxs: [NSTextField] = []
        var controlFlagBoxs: [NSPopUpButton] = []
        var txmitDatas: [NSTextField] = []
        var encDatas: [NSTextField] = []
        var senseidDatas: [NSTextField] = []
        for i in 0 ..< self.connectors.count {
            if checkBoxes[i].state == NSOnState {
                connectors.append(self.connectors[i])
                typeBoxs.append(self.typeBoxs[i])
                controlFlagBoxs.append(self.controlFlagBoxs[i])
                txmitDatas.append(self.txmitDatas[i])
                encDatas.append(self.encDatas[i])
                senseidDatas.append(self.senseidDatas[i])
            }
        }
        
        let s = NSMutableString()
        s.appendString(PCIID + "\n\n")
        s.appendString("ATI Connectors Data: \n")
        s.appendString(systemFBname[FBComboBox!.indexOfSelectedItem] + "\n")
        s.appendString(systemFBvalue[FBComboBox!.indexOfSelectedItem] + "\n\n")
        
        // Analyze Origin Framebuffer
        var split = systemFBvalue[FBComboBox!.indexOfSelectedItem].componentsSeparatedByString("\n")
        let originTypes = split[0].componentsSeparatedByString(", ")
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
        for j in 1 ..< split.count - 1 {
            let range = split[j].startIndex.advancedBy(20) ..< split[j].startIndex.advancedBy(24)
            let placeholder = split[j].substringWithRange(range)
            originPlaceholders.append(placeholder)

            let range2 = split[j].startIndex.advancedBy(28) ..< split[j].startIndex.advancedBy(30)
            let hotplugin = split[j].substringWithRange(range2)
            originHotplugins.append(hotplugin)
        }
        
        s.appendString("ATI Connectors Patch: \n")
        
        var record: [Int] = []
        // record defines which connector data will be the postion.
        // value > 0 means ROM connector data
        // value < 0 means Origin Framebuffer connector data
        
        if connectors.count == 0 {
            let alert = NSAlert()
            alert.messageText = "Please select at least 1 connector."
            alert.runModal()
            return
        }
        if opt3.selectedSegment == 1 {
            for i in 1...originTypes.count {
                record.append(-i)
            }
            var choose: [Bool] = []
            for _ in 1...connectors.count {
                choose.append(false)
            }
            
            // fill in record if connector type is same
            for j in 0 ..< connectors.count {
                for k in 0 ..< originTypes.count {
                    if (originTypesID[k] == connectors[j].type) && (record[k] < 0) {
                        record[k] = j + 1
                        choose[j] = true
                        break
                    }
                }
            }
            
            // fill in record if no same connector type
            for j in 0 ..< connectors.count {
                if !choose[j] {
                    for k in 0 ..< originTypes.count {
                        if record[k] < 0 {
                            record[k] = j + 1
                            choose[j] = true
                            break
                        }
                    }
                }
            }
            
            // delete unused
            for j in 0 ..< record.count {
                if record[j] < 0 {
                    record[j] = 0
                }
            }
        }
        else{
            var i = 1
            while i <= connectors.count {
                record.append(i)
                i += 1
            }
            while i <= originTypes.count {
                record.append(0)
                i += 1
            }
        }
        
        for i in 0 ..< record.count {
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
        for i in 0 ..< record.count {
            if (record[i] == 0) {
                if mode == 1 {
                    s.appendString("0000000000000000")
                }
                s.appendString("00000000000000000000000000000000\n")
                continue
            }
            
            let j = record[i] - 1
            // Connector type and Control Flag
            switch (connectors[j].type) {
                case 1: // DDVI
                    s.appendString("04000000")
                    switch (controlFlagBoxs[j].indexOfSelectedItem) {
                        case 0: s.appendString("14000000")
                        case 1: s.appendString("14020000")
                        case 2: s.appendString("04020000")
                        default: s.appendString("<Error> ")
                    }
                    s.appendString("0001")
                case 2: // DP
                    s.appendString("00040000")
                    switch (controlFlagBoxs[j].indexOfSelectedItem) {
                        case 0: s.appendString("04030000")
                        case 1: s.appendString("04060000")
                        default: s.appendString("<Error> ")
                    }
                    s.appendString("0001")
                case 3: // HDMI
                    s.appendString("00080000040200000071")
                case 4: // LVDS
                    s.appendString("02000000")
                    switch (controlFlagBoxs[j].indexOfSelectedItem) {
                        case 0: s.appendString("40000000")
                        case 1: s.appendString("00010000")
                        default: s.appendString("<Error> ")
                    }
                    s.appendString("0901")
                case 5: // SDVI
                    s.appendString("00020000")
                    switch (controlFlagBoxs[j].indexOfSelectedItem) {
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
                if i >= originPlaceholders.count {
                    s.appendString("0000")
                }
                else {
                    s.appendString(originPlaceholders[i])
                }
            }
            
            if mode == 1 {
                s.appendString("00000000")
            }
            
            s.appendString(txmitDatas[j].stringValue + encDatas[j].stringValue)
            if opt2.selectedSegment == 0 {
                if connectors[j].type == 4 {
                    s.appendString("00")
                }
                else {
                    allocateHotplugin += 1
                    s.appendString("0\(allocateHotplugin)")
                }
            }
            else {
                if i >= originHotplugins.count {
                    s.appendString("00")
                }
                else {
                    s.appendString(originHotplugins[i])
                }
            }
            
            s.appendString(senseidDatas[j].stringValue)
            if mode == 1 {
                s.appendString("00000000")
            }
            s.appendString("\n")
        }
        
        // Special Condition Warning
        if opt3.selectedSegment == 0 && connectors.count > originTypes.count {
            s.appendString("\nWarning: Number of connectors should be \(originTypes.count)\n")
        }
        if controller.stringValue == "AMD6000Controller" && connectors[0].type == 4 && encDatas[0].stringValue == "00" {
            s.appendString("\nWarning: You may need to change the enc of LVDS to 01 to avoid screen mess\n")
        }
        
        let alert = NSAlert()
        alert.messageText = s as String
        alert.runModal()
    }
    
    func exitButtonPressed() {
        exit(0)
    }
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        let i = FBComboBox!.indexOfSelectedItem
        FBInf?.stringValue = systemFBvalue[i]
        if systemFBname[i].hasPrefix("---") {
            saveButton!.enabled = false
        }
        else {
            saveButton!.enabled = true
        }
    }
}