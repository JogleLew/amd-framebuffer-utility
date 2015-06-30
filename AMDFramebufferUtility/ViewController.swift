//
//  ViewController.swift
//  AMDFrameBufferUtility
//
//  Created by jogle on 15/6/28.
//  Copyright (c) 2015年 joglelew. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var connectors: [Connector] = []
    var PCIID: String = ""
    
    @IBOutlet weak var processStatus: NSImageView!

    @IBOutlet weak var filePath: NSTextField!
    @IBOutlet weak var showDataButton: NSButton!
    
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
            filePath.stringValue = ""
            processStatus.image = nil
            return
        }
        // Show path on window
        var pathURL: NSURL = panel.URLs[0] as! NSURL
        filePath.stringValue = pathURL.path!
        
        // Run radeon_bios_decode
        var result = runProgram("radeon_bios_decode", inputFile: filePath.stringValue)
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
            processStatus.image = NSImage(named: "incorrect.png")
            showDataButton.enabled = false
            showDataButton.hidden = true
            return
        }
        processStatus.image = NSImage(named: "correct.png")
        showDataButton.enabled = true
        showDataButton.hidden = false
        
        // Prepare connectors array
        connectors = []
        
        // Get type, hotplugin, senseid
        var hotpluginAllocate = 1
        var type = 0
        var hotplugin = ""
        var senseid = ""
        for var i = 0; i < splitResult.count; i++ {
            if (splitResult[i].hasPrefix("Connector at index")) {
                i++
                var items = splitResult[i].componentsSeparatedByString(" ")
                var t = items[items.count - 2]
                if (t.hasPrefix("LVDS")) {
                    type = 4
                    hotplugin = "00"
                }
                else if (t.hasPrefix("HDMI")) {
                    type = 3
                    hotplugin = "0\(hotpluginAllocate++)"
                }
                else if (t.hasPrefix("VGA")) {
                    type = 5
                    hotplugin = "0\(hotpluginAllocate++)"
                }
                else if (t.hasPrefix("DVI")) {
                    type = 2
                    hotplugin = "0\(hotpluginAllocate++)"
                }
                else if (t.hasPrefix("DisplayPort")) {
                    type = 1
                    hotplugin = "0\(hotpluginAllocate++)"
                }
                else {
                    type = 0
                    hotplugin = ""
                }
                i += 2
                items = splitResult[i].componentsSeparatedByString(" ")
                senseid = items[items.count - 1].substringFromIndex(advance(items[items.count - 1].startIndex, 2))
                if (count(senseid) == 1) {
                    senseid = "0" + senseid
                }
                var c = Connector(type: type, hotplugin: hotplugin, senseid: senseid)
                connectors.append(c)
            }
        }
        
        // Run redsock_bios_decoder
        result = runProgram("redsock_bios_decoder", inputFile: filePath.stringValue)
        splitResult = result.componentsSeparatedByString("\n")
        
        // Get txmit, enc
        var txmit = ""
        var enc = ""
        var currentPos = 0
        for var i = 0; i < splitResult.count; i++ {
            if (splitResult[i].hasPrefix("Connector Object Id")) {
                i++
                var items = splitResult[i].componentsSeparatedByString(" ")
                for var j = 0; j < items.count; j++ {
                    if (items[j] == "txmit") {
                        j++
                        txmit = items[j].substringFromIndex(advance(items[j].startIndex, 2));
                        if (count(txmit) > 2) {
                            txmit = items[j].substringToIndex(advance(items[j].endIndex, 2 - count(txmit)))
                        }
                        connectors[currentPos].setTxmit(txmit)
                    }
                    if (items[j] == "enc") {
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
                        connectors[currentPos].setEnc(enc)
                    }
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

