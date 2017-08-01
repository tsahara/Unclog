//
//  IPPacket.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/17.
//
//

import Foundation

// https://tools.ietf.org/html/rfc791

public class IPv4Packet: BasePacket, IPPacket {
    var proto: UInt8 {
        get {
            return getu8(9)
        }
    }
    
    var src: IPAddress {
        return IPv4Address(data: self.data, offset: self.header_offset + 12)
    }

    var dst: IPAddress {
        return IPv4Address(data: self.data, offset: self.header_offset + 16)
    }
}
