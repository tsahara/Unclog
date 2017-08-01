//
//  Data.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/17.
//
//

import Foundation

extension Data {
    public func getu32(_ offset: Int) -> UInt32 {
        var val = UInt32(self[offset]) << 24
        val |= UInt32(self[offset+1]) << 16
        val |= UInt32(self[offset+2]) << 8
        val |= UInt32(self[offset+3])
        return val
    }
}
