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

    let time_created: Date

    init(syn tcp: TCPPacket) {
        self.srcip   = tcp.ip.src
        self.srcport = tcp.srcport
        self.dstip   = tcp.ip.dst
        self.dstport = tcp.dstport

        self.time_created = tcp.pkt.timestamp

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
        let state = self.state(to)
        let receiver_state = self.state(to.reverse)

        if tcp.syn == 1 {
            state.isn = tcp.seqnum
        }

        if tcp.fin == 1 {
            state.fin_received = true
            if receiver_state.fin_received {
                print("connection closed")
                print_statistics()
            }
        }

        if tcp.ack == 1 {
//            let datapkt = find_packet {
//                return $0.seqnum < tcp.acknum && $0.seqnum + UInt32($0.payload_length) >= tcp.acknum
//            }
//            if datapkt != nil {
//                //let rtt = tcp.pkt.timestamp.timeIntervalSince(datapkt!.pkt.timestamp)
//                //print("-> \(rtt)")
//            }
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

        let arrow = (to == .server) ? "-->" : "<--"
        let timeoffset = tcp.pkt.timestamp - self.time_created

        var line = arrow + String(format: " %.6f ", timeoffset)

        if tcp.syn == 1 && tcp.ack == 0 {
            line += "SYN"
        } else if tcp.syn == 1 && tcp.ack == 1 {
            line += "SYN/ACK"
        } else if tcp.payload_length == 0 && tcp.ack == 1 {
            line += "ACK window=\(tcp.window)"
        } else {
            line += "TSN = \(state.tsn), seq = \(tcp.seqnum) => \(tcp.payload_length) window=\(tcp.window)"
        }
        print(line)

        if tcp.syn == 1 {
            state.tsn = tcp.seqnum &+ 1
        } else {
            state.tsn = tcp.seqnum &+ UInt32(tcp.payload_length)
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

    func print_statistics() {
        print("TCP \(srcip) port \(srcport) -> \(dstip) port \(dstport)")
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

    // Transmit Sequence Number: sequence number of the first byte of the next packet
    var tsn: UInt32 = 0

    var fin_received = false
}
