//
//  ConnectorData.swift
//  AMDFrameBufferUtility
//
//  Created by jogle on 15/6/28.
//  Copyright (c) 2015年 joglelew. All rights reserved.
//

import Foundation

class Connector {
    var type: Int = 0
        // type = 0 -> nil
        // type = 1 -> DP
        // type = 2 -> DVI
        // type = 3 -> HDMI
        // type = 4 -> LVDS
        // type = 5 -> VGA
    var txmit: String = ""
    var enc: String = ""
    var hotplugin: String = ""
    var senseid: String = ""

    init(type: Int, hotplugin: String, senseid: String) {
        self.type = type
        self.hotplugin = hotplugin
        self.senseid = senseid
    }
    
    func setTxmit(txmit: String) {
        self.txmit = txmit
    }
    
    func setEnc(enc: String) {
        self.enc = enc
    }
    
    func toString() -> String {
        var result = ""
        switch (type) {
            case 1: result += "DP "
            case 2: result += "DVI "
            case 3: result += "HDMI "
            case 4: result += "LVDS "
            case 5: result += "VGA "
            default: result += "--- "
        }
        result += "txmit \(txmit) "
        result += "enc \(enc) "
        result += "hotplugin \(hotplugin) "
        result += "senseid \(senseid)"
        return result
    }
    
    func toRaw() -> String {
        var result = ""
        switch (type) {
            case 1: result += "00 04 00 00 04 06 00 00 00 71 00 00 "
            case 2: result += "04 00 00 00 14 02 00 00 00 01 00 00 "
            case 3: result += "00 08 00 00 04 02 00 00 00 71 00 00 "
            case 4: result += "02 00 00 00 40 00 00 00 09 01 00 00 "
            case 5: result += "10 00 00 00 10 00 00 00 00 01 00 00 "
            default: result += "00 00 00 00 00 00 00 00 00 00 00 00 "
        }
        result += txmit + " "
        result += enc + " "
        result += hotplugin + " "
        result += senseid
        return result
    }
}