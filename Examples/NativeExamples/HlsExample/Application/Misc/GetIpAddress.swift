//
//  GetIpAddress.swift
//  HlsExample
//
//  Created by fuziki on 2021/08/09.
//

import Foundation

func getIpAddress() -> String? {
    var res: String?
    var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
    getifaddrs(&ifaddrsPtr)
    for targetPtr in sequence(first: ifaddrsPtr!, next: { $0.pointee.ifa_next }) {
        let ifaddrs: ifaddrs = targetPtr.pointee
        let saFamily = ifaddrs.ifa_addr.pointee.sa_family
        guard (saFamily == UInt8(AF_INET) || saFamily == UInt8(AF_INET6)),
              String(cString: ifaddrs.ifa_name) == "en0" else {
            continue
        }
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(ifaddrs.ifa_addr,
                    socklen_t(ifaddrs.ifa_addr.pointee.sa_len),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    socklen_t(0),
                    NI_NUMERICHOST)
        res = String(cString: hostname)
    }
    freeifaddrs(ifaddrsPtr)
    return res
}
