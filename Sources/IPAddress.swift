//
//  IPAddress.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/22.
//
//

import Foundation

class IPAddress : Hashable {
    var hashValue: Int { get { return 0 } }
    var string: String { get { return "" } }

    static func == (lhs: IPAddress, rhs: IPAddress) -> Bool {
        return lhs.string == rhs.string
    }
}
