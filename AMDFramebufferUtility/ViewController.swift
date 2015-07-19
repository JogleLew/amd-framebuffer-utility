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
    var PCIID: String = ""
    
    @IBOutlet weak var processStatus: NSImageView!
    @IBOutlet weak var showDataButton: NSButton!
    @IBOutlet weak var pathControl: NSPathControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showDataButton.enabled = false
        showDataButton.hidden = true
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func selectButtonPressed(sender: NSButtonCell) {
    
        // Open the panel for user to select ROM file
        var panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.runModal()
        
        // If user not select a file, set void path and pic
        if panel.URLs.count == 0 {
            pathControl.stringValue = ""
            processStatus.image = nil //NSImage(named: "NSStatusNone");
            return
        }
        // Show path on window
        var pathURL: NSURL = panel.URLs[0] as! NSURL
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
            return
        }
        processStatus.image = NSImage(named: "NSStatusAvailable");
        /*processStatus.image = NSImage(named: "correct.png")*/
        showDataButton.enabled = true
        showDataButton.hidden = false
        
        // Prepare connectors array
        connectors = []
        
        // Get senseid
        var hotpluginAllocate = 1
        var type = 0
        var hotplugin = ""
        var senseid = ""
        for var i = 0; i < splitResult.count; i++ {
            if (splitResult[i].hasPrefix("Connector at index")) {
                i += 3
                var items = splitResult[i].componentsSeparatedByString(" ")
                senseid = items[items.count - 1].substringFromIndex(advance(items[items.count - 1].startIndex, 2))
                if (count(senseid) == 1) {
                    senseid = "0" + senseid
                }
                var c = Connector()
                c.setSenseid(senseid)
                connectors.append(c)
            }
        }
        // Merge same senseid
        for var i = 1; i < connectors.count; i++ {
            if connectors[i].senseid == connectors[i - 1].senseid {
                connectors.removeAtIndex(i)
                i--
            }
        }
        
        // Run redsock_bios_decoder
        result = runProgram("redsock_bios_decoder", inputFile: pathControl.stringValue)
        splitResult = result.componentsSeparatedByString("\n")
        
        // Get type, txmit, enc
        var txmit = ""
        var enc = ""
        var duallink = ""
        var currentPos = 0
        var mergeFlag = false
        for var i = 0; i < splitResult.count; i++ {
            if (splitResult[i].hasPrefix("Connector Object Id")) {
                var items = splitResult[i].componentsSeparatedByString(" ")
                switch items[3] {
                    case "[1]": connectors[currentPos].setType(5) //SDVI-I
                                connectors[currentPos].setControlFlag(1)
                    case "[2]": connectors[currentPos].setType(1) //DDVI-I
                                connectors[currentPos].setControlFlag(1)
                    case "[3]": connectors[currentPos].setType(5) //SDVI-D
                                connectors[currentPos].setControlFlag(0)
                    case "[4]": connectors[currentPos].setType(1) //DDVI-D
                                connectors[currentPos].setControlFlag(0)
                    case "[5]": connectors[currentPos].setType(6) //VGA
                    case "[12]", "[13]": connectors[currentPos].setType(3)//HDMI
                    case "[14]": connectors[currentPos].setType(4) //LVDS
                    case "[19]", "[20]": connectors[currentPos].setType(2) //DP
                    default: connectors[currentPos].setType(0) //Null
                }
                i++
                items = splitResult[i].componentsSeparatedByString(" ")
                for var j = 0; j < items.count; j++ {
                    if items[j] == "txmit" {
                        j++
                        txmit = items[j].substringFromIndex(advance(items[j].startIndex, 2));
                        if (count(txmit) > 2) {
                            txmit = items[j].substringToIndex(advance(items[j].endIndex, 2 - count(txmit)))
                        }
                    }
                    if items[j] == "enc" {
                        j++
                        enc = ""
                        var isEnc = false
                        for c in items[j] {
                            if (c >= "0" && c <= "9" && isEnc) {
                                enc += "\(c)"
                            }
                            if (c == "x") {
                                isEnc = true
                            }
                        }
                        if (count(enc) == 1) {
                            enc = "0" + enc
                        }
                    }
                    if items[j] == "[duallink" {
                        j++
                        var x = advance(items[j].startIndex, 2)
                        var y = advance(items[j].startIndex, 3)
                        duallink = items[j].substringWithRange(Range<String.Index>(start: x, end: y))
                        if connectors[currentPos].type == 2 && duallink == "1" {
                            connectors[currentPos].setControlFlag(1)
                        }
                    }
                }
                
                if mergeFlag {
                    if enc == "10" {
                        connectors[currentPos].setTxmit(txmit)
                    }
                    else {
                        connectors[currentPos].setEnc(enc)
                    }
                }
                else {
                    connectors[currentPos].setTxmit(txmit)
                    connectors[currentPos].setEnc(enc)
                }
                
                if connectors[currentPos].type == 1 {
                    mergeFlag = !mergeFlag
                    continue
                }
                currentPos++
            }
        }
        
        // Print debug information
        for i in connectors {
            println(i.toString())
        }
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        var viewController = segue.destinationController as! ResultViewController
        viewController.connectors = connectors
        viewController.PCIID = PCIID.uppercaseString
    }
    
    func runProgram(name: String, inputFile: String) -> String {
        var task = NSTask()
        task.launchPath = "/bin/sh"
        
        // Get the path of program
        var tempDir = NSBundle.mainBundle().pathForResource(name, ofType: nil)
        var dir = "\(tempDir)"
        
        // Delete the disgusting "Optional("...")"
        dir = dir.substringFromIndex(advance(dir.startIndex, 10))
        dir = dir.substringToIndex(advance(dir.endIndex, -2))
        var inputFileHandleBlank = inputFile.stringByReplacingOccurrencesOfString(" ", withString: "\\ ")
        task.arguments = ["-c", "\(dir) < \(inputFileHandleBlank)"]
        
        // Define
        var pipe = NSPipe()
        task.standardOutput = pipe
        
        var file = NSFileHandle()
        file = pipe.fileHandleForReading
        
        task.launch()
        var data = file.readDataToEndOfFile()
        var context1 = NSString(data: data, encoding: NSUTF8StringEncoding)
        println(context1)
        return "\(context1)"
    }
}

