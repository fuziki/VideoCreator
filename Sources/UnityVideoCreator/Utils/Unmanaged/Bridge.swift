//
//  Bridge.swift
//
//
//  Created by fuziki on 2021/07/28.
//

import Foundation

// swiftlint:disable identifier_name

// UnsafeRawPointer == UnsafePointer<Void> == (void*)
func __bridge<T: AnyObject>(_ ptr: UnsafeRawPointer) -> T {
    return Unmanaged.fromOpaque(ptr).takeUnretainedValue()
}
