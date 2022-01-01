//
//  SampleBufferDisplayView.swift
//  NativeExamples
//
//  Created by fuziki on 2021/12/25.
//

import AVFoundation
import CoreImage
import Combine
import Foundation
import SharedGameView

class SampleBufferDisplayView: CPView {
#if !os(macOS)
    override class var layerClass: AnyClass {
        get { return AVSampleBufferDisplayLayer.self }
    }

    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }
#else
    let sampleBufferDisplayLayer = AVSampleBufferDisplayLayer()
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer = sampleBufferDisplayLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
#endif

    private var cancellables: Set<AnyCancellable> = []
    internal func setup(sampleBufferStream: AnyPublisher<CMSampleBuffer, Never>) {
        cancellables = []

        sampleBufferStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (sampleBuffer: CMSampleBuffer) in
                guard let self = self else { return }
                if let error = self.sampleBufferDisplayLayer.error {
                    print("sampleBufferDisplayLayer.error: \(error)")
                    return
                }
                if !self.sampleBufferDisplayLayer.isReadyForMoreMediaData { return }
                print("status: \(self.sampleBufferDisplayLayer.status == .rendering ? ".rendering" : "failed")")
                self.sampleBufferDisplayLayer.enqueue(sampleBuffer)
            }
            .store(in: &cancellables)
    }
}

struct SampleBufferDisplayViewRepresentable: CPViewRepresentable {
    private let sampleBufferDisplayView = SampleBufferDisplayView(frame: .zero)

    public init(sampleBufferStream: AnyPublisher<CMSampleBuffer, Never>) {
        sampleBufferDisplayView.setup(sampleBufferStream: sampleBufferStream)
    }

#if !os(macOS)
    public typealias UIViewType = SampleBufferDisplayView
    private typealias ViewType = UIViewType
    public func makeUIView(context: Context) -> UIViewType {
        return makeView(context: context)
    }
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        updateView(uiView, context: context)
    }
#else
    public typealias NSViewType = SampleBufferDisplayView
    private typealias ViewType = NSViewType
    public func makeNSView(context: Context) -> NSViewType {
        return makeView(context: context)
    }
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        updateView(nsView, context: context)
    }
#endif

    private func makeView(context: Context) -> ViewType {
        return sampleBufferDisplayView
    }
    private func updateView(_ view: ViewType, context: Context) {
    }
}
