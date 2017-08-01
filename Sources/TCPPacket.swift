//
//  TCPPacket.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/17.
//
//

import Foundation

// https://tools.ietf.org/html/rfc793

public class TCPPacket: BasePacket {
    let ip: IPPacket

    init(ipv4: IPv4Packet) {
        self.ip = ipv4
        super.init(pkt: ipv4.pkt, offset: ipv4.header_offset + 20)
    }

    var srcport: UInt16 {
        get {
            return getu16(0)
        }
    }

    var dstport: UInt16 {
        get {
            return getu16(2)
        }
    }

    var seqnum: UInt32 {
        get {
            return getu32(4)
        }
    }
    
    var acknum: UInt32 {
        get {
            return getu32(8)
        }
    }

    var flags: UInt8 {
        get {
            return getu8(13)
        }
    }
    
    var fin: Int {
        get {
            return Int(flags) & 1
        }
    }
    
    var syn: Int {
        get {
            return Int(flags >> 1) & 1
        }
    }

    var ack: Int {
        get {
            return Int(flags >> 4) & 1
        }
    }

    var fivetuple: FiveTuple {
        get {
            return FiveTuple(srcip: self.ip.src, srcport: self.srcport, dstip: self.ip.dst, dstport: self.dstport, proto: UInt8(IPPROTO_TCP))
        }
    }
}
