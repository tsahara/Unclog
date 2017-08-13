//
//  TCPOption.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/08/06.
//
//

import Foundation

class TCPOption {
    let kind: Int
    let length: Int

    init(kind: UInt8, length: UInt8) {
        self.kind = Int(kind)
        self.length = Int(length)
    }

    static func parse(kind: UInt8, length: UInt8, data: Data, ptr: Int) -> TCPOption {
        return UnknownTCPOption(kind: kind, length: length)
    }
}

class TCPTimeStampOption {
    
}

class UnknownTCPOption : TCPOption {
    let bytes: [UInt8] = []
}
