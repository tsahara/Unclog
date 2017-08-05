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

        input(to: .server, tcp: tcp)
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

    func input(to: DirectedTo, tcp: TCPPacket) {
        self.packets.append(tcp)

        if tcp.syn == 1 {
            switch to {
            case .server:
                client_state.isn = tcp.seqnum
            case .client:
                server_state.isn = tcp.seqnum
            }
        }

        let state = self.state(to)
        let receiver_state = self.state(to.reverse)

        if tcp.ack == 0 {
            return
        }

        let datapkt = find_packet {
            if let isn = state.isn, let r_isn = receiver_state.isn {
                if ($0.seqnum > isn) {
                    print("tcp seq=+\($0.seqnum - isn), plen=\($0.payload_length) new tcp: ack=\(tcp.acknum - r_isn)")
                }
            }
            return $0.seqnum < tcp.acknum && $0.seqnum + UInt32($0.payload_length) >= tcp.acknum
        }
        if datapkt != nil {
            let rtt = tcp.pkt.timestamp.timeIntervalSince(datapkt!.pkt.timestamp)
            print("-> \(rtt)")
        }
        if to == .server {
            if client_state.last_seq == nil {
                client_state.last_seq = tcp.seqnum
            }
            if client_state.last_ack == nil {
                client_state.last_ack = tcp.acknum
            }
        }

        if to == .server {
            client_state.last_seq = tcp.seqnum
            client_state.last_ack = tcp.acknum
        }
        self.packets.append(tcp)
    }

    func state(_ to: DirectedTo) -> TCPState {
        switch to {
        case .server:
            return client_state
        case .client:
            return server_state
        }
    }
}

enum DirectedTo {
    case client
    case server

    var reverse: DirectedTo {
        get {
            switch self {
            case .client:
                return .server
            case .server:
                return .client
            }
        }
    }
}

class TCPState {
    var isn: UInt32? = nil
    var last_seq: UInt32? = nil
    var last_ack: UInt32? = nil
}
