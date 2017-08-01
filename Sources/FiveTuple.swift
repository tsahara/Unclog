//
//  FiveTuple.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/29.
//
//

import Foundation

struct FiveTuple : Hashable {
    let srcip: IPAddress
    let srcport: UInt16
    let dstip: IPAddress
    let dstport: UInt16
    let proto: UInt8

    var hashValue: Int {
        get {
            return 0
        }
    }

    static func == (lhs: FiveTuple, rhs: FiveTuple) -> Bool {
        return lhs.srcip == rhs.srcip &&
            lhs.srcport == rhs.srcport &&
            lhs.dstip == rhs.dstip &&
            lhs.srcport == rhs.srcport &&
            lhs.proto == rhs.proto
    }

    func reverse() -> FiveTuple {
        return FiveTuple(srcip: self.dstip, srcport: self.dstport, dstip: self.srcip, dstport: self.srcport, proto: self.proto)
    }
}
