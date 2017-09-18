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

    var client_state = TCPState()
    var server_state = TCPState()

    let time_created: Date

    let up_flow: TLSFlow

    // number of bytes has been passed to upper layer
    var up_offset = 0

    init(syn tcp: TCPPacket) {
        self.srcip   = tcp.ip.src
        self.srcport = tcp.srcport
        self.dstip   = tcp.ip.dst
        self.dstport = tcp.dstport

        self.time_created = tcp.pkt.timestamp

        client_state.append(pkt: tcp)

        //if self.dstport == 443 {
        self.up_flow = TLSFlow()
        
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

    func input(to: DirectedTo, tcp: TCPPacket) {
        let state = self.state(to)
        let receiver_state = self.state(to.reverse)

        if tcp.syn == 1 {
            state.isn = tcp.seqnum

            for opt in tcp.options {
                if opt.kind == Int(TCPOPT_WINDOW) {
                    state.window_scale = Int((opt as! TCPWindowScaleOption).shift_cnt)
                }
            }
        }

        if tcp.fin == 1 {
            state.fin_received = true
            if receiver_state.fin_received {
                print("connection closed")
                print_statistics()
            }
        }

        if tcp.syn == 0 && tcp.fin == 0 && tcp.payload_length > 0 {
            state.send_window.add(pkt: tcp)
            print("window first continuous block: \(state.send_window.head_block_size)")
        }

        if tcp.ack == 1 {
            let datapkt = receiver_state.find_packet {
                return $0.seqnum < tcp.acknum && $0.seqnum + UInt32($0.payload_length) >= tcp.acknum
            }
            if datapkt != nil {
                //let rtt = tcp.pkt.timestamp.timeIntervalSince(datapkt!.pkt.timestamp)
                //print("-> \(rtt)")
            }

            receiver_state.last_ack = tcp.acknum
        }

        if to == .server {
            if client_state.last_seq == nil {
                client_state.last_seq = tcp.seqnum
            }
        }

        if to == .server {
            client_state.last_seq = tcp.seqnum
        }

        let arrow = (to == .server) ? "-->" : "<--"
        let timeoffset = tcp.pkt.timestamp - self.time_created

        var line = arrow + String(format: " %.6f ", timeoffset)

        if tcp.syn == 1 && tcp.ack == 0 {
            line += "SYN options=\(tcp.options)"
        } else if tcp.syn == 1 && tcp.ack == 1 {
            line += "SYN/ACK options=\(tcp.options)"

            if let syn = receiver_state.find_packet(cond: { $0.syn == 1 }) {
                let rtt = tcp.pkt.timestamp.timeIntervalSince(syn.pkt.timestamp)
                print("syn rtt = \(rtt)")
            }
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

        state.append(pkt: tcp)
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

    var window_scale: Int?

    var fin_received = false

    // TCP packets sent by that TCP endpoint
    var packets: [TCPPacket] = []

    var send_window = TCPWindow()

    var up_data = Data()

    func append(pkt: TCPPacket) {
        packets.append(pkt)
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

class TCPWindow {  // or Packet Reassembly Queue ???
    var left: UInt64 = 0
    var head_block_size: Int64 = 0

    var packets: [TCPPacket] = []

    func add(pkt new: TCPPacket) {
        if packets.count == 0 {
            self.left = UInt64(new.seqnum)
            self.head_block_size = Int64(new.payload_length)
            self.packets.append(new)
        } else {
            for i in 0..<packets.count {
                if new.seqnum < packets[i].seqnum {
                    self.packets.insert(new, at: i)
                    if i > 0 {
                        let overwrap = Int64(self.left) + self.head_block_size - Int64(new.seqnum)
                        if overwrap >= 0 {
                            self.head_block_size += Int64(new.seqnum) - overwrap
                            for i in i..<packets.count {
                                let overwrap = Int64(self.left) + self.head_block_size - Int64(packets[i].seqnum)
                                if overwrap >= 0 {
                                    self.head_block_size += Int64(packets[i].seqnum) - overwrap
                                } else {
                                    break
                                }
                            }
                        }
                    }
                    return
                }
            }
            self.packets.append(new)
            let overwrap = Int64(self.left) + self.head_block_size - Int64(new.seqnum)
            if overwrap >= 0 {
                self.head_block_size += Int64(packets.last!.seqnum) - overwrap
            }
        }
    }
}
