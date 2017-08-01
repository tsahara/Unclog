//
//  BasePacket.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/17.
//
//

import Foundation

public class BasePacket {
    let pkt: PcapPacket
    let header_offset: Int

    init(pkt: PcapPacket, offset: Int) {
        self.pkt = pkt
        self.header_offset = offset
    }

    var data: Data {
        get {
            return self.pkt.data
        }
    }

    func getu8(_ offset: Int) -> UInt8 {
        let idx = header_offset + offset
        return UInt8(data[idx])
    }

    func getu16(_ offset: Int) -> UInt16 {
        let idx = header_offset + offset
        return UInt16(data[idx]) * 256 + UInt16(data[idx+1])
    }

    func getu32(_ offset: Int) -> UInt32 {
        return data.getu32(header_offset + offset)
    }
}
