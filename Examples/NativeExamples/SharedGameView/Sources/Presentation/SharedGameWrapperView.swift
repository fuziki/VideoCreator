//
//  SharedGameWrapperView.swift
//  SharedGameView
//
//  Created by fuziki on 2021/12/24.
//

import Combine
import Foundation
import SwiftUI

public struct SharedGameWrapperView: CPViewRepresentable {

    let sharedGameView = SharedGameView(frame: .zero)

    public init() {
    }

#if !os(macOS)
    public typealias UIViewType = SharedGameView
    private typealias ViewType = UIViewType
    public func makeUIView(context: Context) -> UIViewType {
        return makeView(context: context)
    }
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        updateView(uiView, context: context)
    }
#else
    public typealias NSViewType = SharedGameView
    private typealias ViewType = NSViewType
    public func makeNSView(context: Context) -> NSViewType {
        return makeView(context: context)
    }
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        updateView(nsView, context: context)
    }
#endif

    private func makeView(context: Context) -> ViewType {
        return sharedGameView
    }
    private func updateView(_ view: ViewType, context: Context) {
    }

    public func didRender(handler: @escaping (_ texture: MTLTexture) -> Void) -> Self {
        sharedGameView.lastNextDrawableTextureHandler = handler
        return self
    }
}
