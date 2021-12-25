//
//  CrossPlatform.swift
//  SharedGameView
//
//  Created by fuziki on 2021/12/25.
//

import Foundation
import SwiftUI

#if !os(macOS)
import UIKit
public typealias CPColor = UIColor
public typealias CPView = UIView
public typealias CPViewRepresentable = UIViewRepresentable
public typealias CPGestureRecognizer = UIGestureRecognizer
public typealias CPTapGestureRecognizer = UITapGestureRecognizer
#else
import AppKit
public typealias CPColor = NSColor
public typealias CPView = NSView
public typealias CPViewRepresentable = NSViewRepresentable
public typealias CPGestureRecognizer = NSGestureRecognizer
public typealias CPTapGestureRecognizer = NSClickGestureRecognizer
#endif
