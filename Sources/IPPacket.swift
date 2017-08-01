//
//  IPPacket.swift
//  Unclog
//
//  Created by Tomoyuki Sahara on 2017/07/22.
//
//

import Foundation

protocol IPPacket {
    var src: IPAddress { get }
    var dst: IPAddress { get }
}
