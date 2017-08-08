//
//  IPv4Address.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/17.
//
//

import Foundation

class IPv4Address: IPAddress, CustomStringConvertible {
    var num: UInt32
    
    init(data: Data, offset: Int) {
        self.num = data.getu32(offset)
    }
    
    init?(str: String) {
        let decimals = str.components(separatedBy: ".")
        if decimals.count != 4 {
            return nil
        }
        
        self.num = 0
        for decimal in decimals {
            guard let byte = UInt32(decimal) else {
                return nil
            }
            self.num = self.num * 256 + byte
        }
    }

    override var hashValue: Int {
        get {
            return Int(num)
        }
    }

    override var string: String {
        get {
            return String(format: "%u.%u.%u.%u", (num >> 24) % 256, (num >> 16) % 256, (num >> 8) % 256, num % 256)
        }
    }

    var description: String {
        get {
            return self.string
        }
    }

}
