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

    var client_state = TCPState()
    var server_state = TCPState()

    init(syn tcp: TCPPacket) {
        self.srcip   = tcp.ip.src
        self.srcport = tcp.srcport
        self.dstip   = tcp.ip.dst
        self.dstport = tcp.dstport
        
        self.packets.append(tcp)

        input(to: .server, pkt: tcp)
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

    func input(to: DirectedTo, pkt: TCPPacket) {
        if pkt.syn == 1 || pkt.ack == 0 {
            self.packets.append(pkt)
            return
        }

        let datapkt = find_packet {
            print("old pkt seqnum=\($0.seqnum), plen=\($0.payload_length) new pkt: ack=\(pkt.acknum)")
            return $0.seqnum < pkt.acknum && $0.seqnum + UInt32($0.payload_length) >= pkt.acknum
        }
        if datapkt != nil {
            let rtt = pkt.pkt.timestamp.timeIntervalSince(datapkt!.pkt.timestamp)
            print("-> \(rtt)")
        }
        if to == .server {
            if client_state.last_seq == nil {
                client_state.last_seq = pkt.seqnum
            }
            if client_state.last_ack == nil {
                client_state.last_ack = pkt.acknum
            }
        }

        if to == .server {
            client_state.last_seq = pkt.seqnum
            client_state.last_ack = pkt.acknum
        }
        self.packets.append(pkt)
    }
}

enum DirectedTo {
    case client
    case server
}

struct TCPState {
    var last_seq: UInt32? = nil
    var last_ack: UInt32? = nil
}
