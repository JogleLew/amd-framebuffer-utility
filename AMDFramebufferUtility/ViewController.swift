//
//  ViewController.swift
//  AMDFrameBufferUtility
//
//  Created by jogle on 15/6/28.
//  Copyright (c) 2015年 joglelew. All rights reserved.
//

import Foundation
import Cocoa

class ViewController: NSViewController {
    var connectors: [Connector] = []
    var fbOriginArray: [String] = []
    var PCIID: String = ""
    
    @IBOutlet weak var processStatus: NSImageView!
    @IBOutlet weak var showDataButton: NSButton!
    
    @IBOutlet weak var pathControl: NSPathControl!

    @IBOutlet weak var fbLengthText: NSTextField!
    @IBOutlet weak var framebufferLength: NSPopUpButton!
    @IBOutlet weak var framebufferOrigin: NSPopUpButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        findSLE()
        
        // Do any additional setup after loading the view.
        showDataButton.enabled = false
        showDataButton.hidden = true
        
        #if DEBUG
            print("Debug Mode: Enable")
        #endif
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func selectButtonPressed(sender: NSButtonCell) {
        #if DEBUG
            print("******************************************")
            print("Select button pressed.")
        #endif
        
        // Open the panel for user to select ROM file
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.runModal()
        
        // If user not select a file, set void path and picture
        if panel.URLs.count == 0 {
            #if DEBUG
                print("User do not select a file.")
            #endif
            pathControl.hidden = true
            processStatus.image = nil //NSImage(named: "NSStatusNone");
            return
        }
        
        // Show path on window
        let pathURL: NSURL = panel.URLs[0] 
        #if DEBUG
            print("Get URL: \(pathURL)")
        #endif
        pathControl.hidden = false
        pathControl.stringValue = pathURL.path!
        
        // Run radeon_bios_decode
        var result = runProgram("radeon_bios_decode", inputFile: pathControl.stringValue)
        var splitResult = result.componentsSeparatedByString("\n")

        // Check ROM File Validation
        var isValid = false
        for s in splitResult {
            if (s.hasPrefix("PCI ID")) {
                isValid = true
                PCIID = s
                break
            }
        }
        
        // Put picture to show the validation of ROM file
        if (!isValid){
            processStatus.image = NSImage(named: "NSStatusUnavailable");
            /*processStatus.image = NSImage(named: "incorrect.png")*/
            showDataButton.enabled = false
            showDataButton.hidden = true
            #if DEBUG
                print("ROM File: Invalid")
            #endif
            return
        }
        processStatus.image = NSImage(named: "NSStatusAvailable");
        /*processStatus.image = NSImage(named: "correct.png")*/
        showDataButton.enabled = true
        showDataButton.hidden = false
        
        // Prepare connectors array
        connectors = []
        
        // Get senseid
        var i = 0
        while i < splitResult.count {
            if (splitResult[i].hasPrefix("Connector at index")) {
                var senseid = "0"
                i += 3
                var items = splitResult[i].componentsSeparatedByString(" ")
                if items[items.count - 1].characters.count >= 3 {
                    senseid = items[items.count - 1].substringFromIndex(items[items.count - 1].startIndex.advancedBy(2))
                }
                else {
                    i -= 2
                    items = splitResult[i].componentsSeparatedByString(" ")
                    if items[items.count - 2] != "LVDS" {
                        continue
                    }
                }
                if (senseid.characters.count == 1) {
                    senseid = "0" + senseid
                }
                let c = Connector()
                c.setSenseid(senseid)
                connectors.append(c)
            }
            i += 1
        }
        
        // Merge same senseid
        i = 1;
        while i < connectors.count {
            if connectors[i].senseid == connectors[i - 1].senseid {
                connectors.removeAtIndex(i)
                i -= 1
            }
            i += 1
        }
        
        // Run redsock_bios_decoder
        result = runProgram("redsock_bios_decoder", inputFile: pathControl.stringValue)
        splitResult = result.componentsSeparatedByString("\n")
        
        // Get type, txmit, enc
        var type = 0
        var controlFlag = 0
        var txmit = ""
        var enc = ""
        var duallink = ""
        var currentPos = -1
        var mergeFlag = false
        
        i = 0;
        while i < splitResult.count {
            type = 0
            controlFlag = 0
            txmit = "00"
            enc = "10"
            duallink = ""
            if (splitResult[i].hasPrefix("Connector Object Id")) {
                var items = splitResult[i].componentsSeparatedByString(" ")
                switch items[3] {
                    case "[1]": type = 5 //SDVI-I
                                controlFlag = 1
                    case "[2]": type = 1 //DDVI-I
                                controlFlag = 1
                    case "[3]": type = 5 //SDVI-D
                                controlFlag = 0
                    case "[4]": type = 1 //DDVI-D
                                controlFlag = 0
                    case "[5]": type = 6 //VGA
                                controlFlag = 0
                    case "[12]", "[13]": type = 3 //HDMI
                                controlFlag = 0
                    case "[14]": type = 4 //LVDS
                                controlFlag = 0
                    case "[19]", "[20]": type = 2 //DP
                                controlFlag = 0
                    default: type = 0 //Null
                                controlFlag = 0
                }
                if type == 0 {
                    continue
                }
                i += 1
                items = splitResult[i].componentsSeparatedByString(" ")
                
                var j = 0
                while j < items.count {
                    if items[j] == "txmit" {
                        j += 1
                        txmit = ""
                        txmit = items[j].substringFromIndex(items[j].startIndex.advancedBy(2));
                        if (txmit.characters.count > 2) {
                            txmit = items[j].substringToIndex(items[j].endIndex.advancedBy(2 - txmit.characters.count))
                        }
                    }
                    if items[j] == "enc" {
                        j += 1
                        enc = ""
                        var isEnc = false
                        for c in items[j].characters {
                            if (c >= "0" && c <= "9" && isEnc) {
                                enc += "\(c)"
                            }
                            if (c == "x") {
                                isEnc = true
                            }
                        }
                        if (enc.characters.count == 1) {
                            enc = "0" + enc
                        }
                    }
                    if items[j] == "[duallink" {
                        j += 1
                        let x = items[j].startIndex.advancedBy(2)
                        let y = items[j].startIndex.advancedBy(3)
                        let range = x ..< y
                        duallink = items[j].substringWithRange(range)
                        if type == 2 && duallink == "1" {
                            controlFlag = 1
                        }
                    }
                    j += 1
                }
                
                if mergeFlag {
                    mergeFlag = false
                    currentPos += 1
                    connectors[currentPos].setType(type)
                    connectors[currentPos].setControlFlag(controlFlag)
                    connectors[currentPos].setTxmit(txmit)
                    connectors[currentPos].setEnc(enc)
                }
                else {
                    if currentPos >= 0 && connectors[currentPos].type == type && controlFlag == 1 && connectors[currentPos].controlFlag == controlFlag && (type == 1 || type == 5 && enc == "10") {
                        mergeFlag = true;
                        if enc == "10" {
                            connectors[currentPos].setTxmit(txmit)
                        }
                        else if enc != "" {
                            connectors[currentPos].setEnc(enc)
                        }
                    }
                    else {
                        currentPos += 1
                        connectors[currentPos].setType(type)
                        connectors[currentPos].setControlFlag(controlFlag)
                        connectors[currentPos].setTxmit(txmit)
                        connectors[currentPos].setEnc(enc)
                    }
                }
            }
            i += 1
        }
        
        // Print debug information
        #if DEBUG
            print("ROM File: Valid")
            print("Connectors Info:")
            for i in connectors {
                print(i.toString())
            }
        #endif
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        let viewController = segue.destinationController as! ResultViewController
        viewController.connectors = connectors
        viewController.PCIID = PCIID.uppercaseString
        if framebufferOrigin.indexOfSelectedItem == 0 {
            viewController.fbOriginName = ""
        }
        else {
            viewController.fbOriginName = fbOriginArray[framebufferOrigin.indexOfSelectedItem - 1]
        }
        if framebufferLength.indexOfSelectedItem == 0 {
            viewController.mode = 1
        }
        else if framebufferLength.indexOfSelectedItem == 1 {
            viewController.mode = 0
        }
        #if DEBUG
            print("******************************************")
            print("Segue to Result View")
        #endif
    }
    
    func runProgram(name: String, inputFile: String) -> String {
        #if DEBUG
            print("\n........Launching program \(name)........")
        #endif
        
        let task = NSTask()
        task.launchPath = "/bin/sh"
        
        // Get the path of program
        let tempDir = NSBundle.mainBundle().pathForResource(name, ofType: nil)!
        let dir = "\(tempDir)"
        
        let dirHandleBlank = dir.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
        let inputFileHandleBlank = inputFile.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
        task.arguments = ["-c", "\(dirHandleBlank) < \(inputFileHandleBlank)"]
        
        // Define
        let pipe = NSPipe()
        task.standardOutput = pipe
        
        var file = NSFileHandle()
        file = pipe.fileHandleForReading
        
        task.launch()
        let data = file.readDataToEndOfFile()
        let context1 = NSString(data: data, encoding: NSUTF8StringEncoding)
        #if DEBUG
            print(context1)
            print("......................................................\n")
        #endif
        
        return "\(context1)"
    }
    
    func findSLE() {
        fbLengthText.stringValue = NSLocalizedString("FB_LENGTH_TEXT", comment: "Framebuffer length")
        framebufferLength.addItemWithTitle(NSLocalizedString("NEW_FRAMEBUFFER_LENGTH", comment: "New framebuffer length"))
        framebufferLength.addItemWithTitle(NSLocalizedString("OLD_FRAMEBUFFER_LENGTH", comment: "Old framebuffer length"))
        framebufferLength.selectItemAtIndex(0)
        framebufferOrigin.addItemWithTitle(NSLocalizedString("PROGRAM_DATA", comment: "Datas that program contains"))
        framebufferOrigin.selectItemAtIndex(0)
        let manager = NSFileManager.defaultManager()
        var partitions: [AnyObject]?
        do {
            partitions = try manager.contentsOfDirectoryAtPath("/Volumes")
        } catch _ as NSError {
            partitions = nil
        }
        if partitions == nil || partitions?.count == 0{
            return
        }
        var names = partitions as! [String]
        for i in 0 ..< names.count {
            let name = names[i]
            if manager.fileExistsAtPath("/Volumes/\(name)/System/Library/Extensions") {
                framebufferOrigin.addItemWithTitle(NSLocalizedString("FROM_PARTITION", comment: "Partition: ") + name)
                fbOriginArray.append(name)
            }
        }
        framebufferOrigin.selectItemAtIndex(1)
    }
}

