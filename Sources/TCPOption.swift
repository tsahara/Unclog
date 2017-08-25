//
//  TCPOption.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/08/06.
//
//

import Foundation

class TCPOption {
    var broken = false

    let kind: Int
    let length: Int

    init(kind: UInt8, length: UInt8) {
        self.kind = Int(kind)
        self.length = Int(length)
    }

    static func parse(kind: UInt8, length: UInt8, data: Data, ptr: Int) -> TCPOption {
        switch Int(kind) {
        case 1:
            return TCPNopOption(kind: kind, length: 0)
        case 3:
            return TCPWindowScaleOption(data.getu8(ptr))
        default:
            return UnknownTCPOption(kind: kind, length: length)
        }
    }
}

class TCPNopOption : TCPOption, CustomStringConvertible {
    var description: String {
        get {
            return "(nop)"
        }
    }
}

class TCPWindowScaleOption : TCPOption, CustomStringConvertible {
    var shift_cnt: UInt8

    init(_ shift_cnt: UInt8) {
        self.shift_cnt = shift_cnt
        super.init(kind: 3, length: 3)
    }

    var description: String {
        get {
            return "(wscale \(shift_cnt))"
        }
    }
}

class UnknownTCPOption : TCPOption {
    let bytes: [UInt8] = []
}
