import Pcap
import Foundation

let vers = String(cString: pcap_lib_version()!)
print("Hello, world = \(vers)!")

// Pcap

var errbuf = [Int8](repeating: 0, count: 2048)
let pcap = pcap_create("en0", &errbuf)
print("err =\(pcap!)")

pcap_set_snaplen(pcap, 128)
pcap_set_timeout(pcap, 1000)
pcap_activate(pcap)
print("snapshot = \(pcap_snapshot(pcap))")

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
                print("flos found")
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
    }
}
