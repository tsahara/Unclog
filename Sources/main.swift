import Pcap
import Foundation

var errbuf = [CChar](repeating: 0, count: Int(PCAP_ERRBUF_SIZE))
let pcap: OpaquePointer

if CommandLine.argc > 1 {
    let filename = CommandLine.arguments[1]
    pcap = pcap_open_offline(filename, &errbuf)
} else {
    pcap = pcap_create("en0", &errbuf)
}
// check if pcap != nil

print("err =\(errbuf)")

pcap_set_snaplen(pcap, 128)
pcap_set_timeout(pcap, 1000)
pcap_activate(pcap)
print("snapshot = \(pcap_snapshot(pcap))")

let linktype = pcap_datalink(pcap)
print("linktype = \(String(cString: pcap_datalink_val_to_name(linktype)))")

var hdr: UnsafeMutablePointer<pcap_pkthdr>?
var data: UnsafePointer<UInt8>?

var flowtable = [FiveTuple: TCPFlow]()

while true {
    let error = pcap_next_ex(pcap, &hdr, &data)
    if error == 1 {
        let pkt = PcapPacket(hdr: hdr!, data: data!)
        if pkt.getu16(12) != 0x800 {
            continue
        }
        let ip = pkt.ipv4
        if ip.proto != UInt8(IPPROTO_TCP) {
            continue
        }
        let tcp = TCPPacket(ipv4: ip)
        if tcp.syn == 1 && tcp.ack == 0 {
            let flow = TCPFlow(syn: tcp)
            print("New Flow: \(ip.src.string) seq=\(tcp.seqnum) ack=\(tcp.acknum) -> \(ip.dst.string)")
            flowtable[tcp.fivetuple] = flow
        }
        if tcp.syn == 1 && tcp.ack == 1 {
            if let flow = flowtable[tcp.fivetuple.reverse()] {
                flow.input(to: .client, tcp: tcp)
                if let syn = flow.find_packet(cond: { $0.syn == 1 }) {
                    let rtt = pkt.timestamp.timeIntervalSince(syn.pkt.timestamp)
                    print("rtt = \(rtt)")
                }
            }
        }
        if tcp.syn == 0 && tcp.ack == 1 {
            if let flow = flowtable[tcp.fivetuple] {
                flow.input(to: .server, tcp: tcp)
            }
            if let flow = flowtable[tcp.fivetuple.reverse()] {
                flow.input(to: .client, tcp: tcp)
            }
        }
    } else if error == -2 {
        break
    }
}
