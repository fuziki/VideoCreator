//
//  TimeProvider.swift
//  SharedGameView
//
//  Created by fuziki on 2021/08/15.
//

import Foundation

public protocol TimeProvider {
    var currentSec: Double { get }
    var currentMicroSec: Int { get }
}

public class DefaultTimeProvider: TimeProvider {
    public init() { }
    public var currentSec: Double {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        return Double(tsc) * Double(tb.numer) / Double(tb.denom) / 1000000000.0
    }
    public var currentMicroSec: Int {
        return Int(currentSec * 1_000_000)
    }
}
