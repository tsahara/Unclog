//
//  TCPFlow.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/17.
//
//

import Foundation

class TCPFlow : Hashable {
    let srcip, dstip: IPAddress
    let srcport, dstport: UInt16

    var packets: [TCPPacket] = []

    init(syn tcp: TCPPacket) {
        self.srcip   = tcp.ip.src
        self.srcport = tcp.srcport
        self.dstip   = tcp.ip.dst
        self.dstport = tcp.dstport
        
        self.packets.append(tcp)
    }

    // for Hashable
    var hashValue: Int {
        get {
            return 0
        }
    }

    // for Hashable:Equatable
    static func == (lhs: TCPFlow, rhs: TCPFlow) -> Bool {
        return lhs.srcip == rhs.srcip && lhs.dstip == rhs.dstip && lhs.srcport == rhs.srcport && lhs.dstport == rhs.dstport
    }

    func find_packet(cond: (TCPPacket) -> Bool) -> TCPPacket? {
        for tcp in packets {
            if cond(tcp) {
                return tcp
            }
        }
        return nil
    }
}
