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
    let options: [TCPOption]

    init(ipv4: IPv4Packet) {
        let header_offset = ipv4.header_offset + ipv4.ihl * 4
        let option_offset = header_offset + 20
        let option_length = Int((ipv4.pkt.getu8(header_offset + 12) & 0xf0) >> 2) - 20

        self.ip = ipv4
        self.options = TCPPacket.parse_options(pkt: ipv4.pkt, offset: option_offset, length: option_length)
        super.init(pkt: ipv4.pkt, offset: header_offset)
    }

    static func parse_options(pkt: PcapPacket, offset option_offset: Int, length option_length: Int) -> [TCPOption] {
        var options: [TCPOption] = []

        var i = 0
        while i < option_length {
            let kind = pkt.getu8(option_offset + i)

            let length: UInt8
            if kind == 0 || kind == 1 {
                length = 1
            } else {
                if i + 1 >= option_length {
                    break
                }
                length = pkt.getu8(option_offset + i + 1)
                if length < 2 || i + Int(length) >= option_length {
                    break
                }
            }

            options.append(TCPOption.parse(kind: kind, length: length, data: pkt.data, ptr: option_offset + i + 2))
            i += Int(length)
        }
        return options
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

    var data_offset: Int {
        get {
            return Int((getu8(12) & 0xf0) >> 2)
        }
    }

    var flags: UInt8 {
        get {
            return getu8(13)
        }
    }
    
    var ack: Int {
        get {
            return Int(flags >> 4) & 1
        }
    }

    var syn: Int {
        get {
            return Int(flags >> 1) & 1
        }
    }

    var fin: Int {
        get {
            return Int(flags) & 1
        }
    }

    var window: UInt16 {
        get {
            return getu16(14)
        }
    }

    var checksum: UInt16 {
        get {
            return getu16(16)
        }
    }

    var urgent_pointer: UInt16 {
        get {
            return getu16(18)
        }
    }

    var fivetuple: FiveTuple {
        get {
            return FiveTuple(srcip: self.ip.src, srcport: self.srcport, dstip: self.ip.dst, dstport: self.dstport, proto: UInt8(IPPROTO_TCP))
        }
    }

    var payload_length: Int {
        get {
            return (self.ip as! IPv4Packet).payload_length - self.data_offset
        }
    }
}
