//
//  ConnectorData.swift
//  AMDFrameBufferUtility
//
//  Created by jogle on 15/6/28.
//  Copyright (c) 2015年 joglelew. All rights reserved.
//

import Foundation

class Connector {
    static var placeholder = 0
        // 0 -> use 00 00 to fill
        // 1 -> keep origin
    static var hotpluginAssign = 0
        // 0 -> reassign from 01 (LVDS always be 00)
        // 1 -> keep origin
    static var keepOriginPostion = 0
        // 0 -> use the order from ROM
        // 1 -> fill into origin framebuffer
    
    var type: Int = 0
        // type = 0 -> Null
        // type = 1 -> Dual - DVI
        // type = 2 -> DisplayPort / eDP
        // type = 3 -> HDMI
        // type = 4 -> LVDS
        // type = 5 -> Single - DVI
        // type = 6 -> VGA
    
    var controlFlag: Int = 0
        // DDVI0 -> 0x0014(DVI-D)
        // DDVI1 -> 0x0214(DVI-I)
        // DDVI2 -> 0x0204(DVI-I Special)
        // DP0 -> 0x0304(High Resolution, duallink=0x2)
        // DP1 -> 0x0604(Normal, duallink=0x1)
        // HDMI0 -> 0x0204(Default)
        // LVDS0 -> 0x0040(Normal)
        // LVDS1 -> 0x0100(High Resolution)
        // SDVI0 -> 0x0014(DVI-D)
        // SDVI1 -> 0x0214(DVI-I)
        // VGA0 -> 0x0010(Default)
    
    var txmit: String = ""
    var enc: String = ""
    var hotplugin: String = ""
    var senseid: String = "00"
    
    func setType(type: Int) {
        self.type = type
    }
    
    func setControlFlag(controlFlag: Int) {
        self.controlFlag = controlFlag
    }
    
    func setSenseid(senseid: String) {
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
            case 1: result += "DDVI "
            case 2: result += "DP/eDP "
            case 3: result += "HDMI "
            case 4: result += "LVDS "
            case 5: result += "SDVI "
            case 6: result += "VGA "
            default: result += "--- "
        }
        result += "txmit \(txmit) "
        result += "enc \(enc) "
        result += "hotplugin \(hotplugin) "
        result += "senseid \(senseid)"
        return result
    }
    
//    func toRaw() -> String {
//        var result = ""
//        switch (type) {
//            // !!!Remains wrong!!! //
//            case 1: result += "04 00 00 00 04 06 00 00 00 71 00 00 "
//            case 2: result += "00 04 00 00 14 02 00 00 00 01 00 00 "
//            case 3: result += "00 08 00 00 04 02 00 00 00 71 00 00 "
//            case 4: result += "02 00 00 00 40 00 00 00 09 01 00 00 "
//            case 5: result += "00 02 00 00 10 00 00 00 00 01 00 00 "
//            case 6: result += "10 00 00 00 10 00 00 00 00 01 00 00 "
//            default: result += "00 00 00 00 00 00 00 00 00 00 00 00 "
//        }
//        result += txmit + " "
//        result += enc + " "
//        result += hotplugin + " "
//        result += senseid
//        return result
//    }
}