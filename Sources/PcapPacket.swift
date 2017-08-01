//
//  PcapPacket.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/16.
//
//

import Foundation
import Pcap

class PcapPacket {
    let pkthdr: pcap_pkthdr
    let data: Data

    init(hdr: UnsafePointer<pcap_pkthdr>, data: UnsafePointer<UInt8>) {
        self.pkthdr = hdr.pointee
        self.data = Data(bytes: data, count: Int(self.pkthdr.caplen))
    }

    func getu8(_ offset: Int) -> UInt8 {
        return UInt8(data[offset])
    }

    func getu16(_ offset: Int) -> UInt16 {
        return UInt16(data[offset]) * 256 + UInt16(data[offset+1])
    }
    
    var ipv4: IPv4Packet {
        get {
            return IPv4Packet(pkt: self, offset: 14)
        }
    }

    var timestamp: Date {
        get {
            let tv = pkthdr.ts
            let ti = TimeInterval(tv.tv_sec) + 1e-6 * TimeInterval(tv.tv_usec)
            return Date(timeIntervalSince1970: ti)
        }
    }
}
