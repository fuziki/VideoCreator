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
    
    let factory = SampleBufferVideoFactory(width: 128, height: 128)
    
    private var cancellables: Set<AnyCancellable> = []
    func setup(textureStream: AnyPublisher<MTLTexture, Never>) {
        cancellables = []
                
        textureStream
            .compactMap { [weak self] (texture: MTLTexture) -> CMSampleBuffer? in
                guard let self = self else { return nil }
                if !self.sampleBufferDisplayLayer.isReadyForMoreMediaData { return nil }
                let cm = self.factory.make(size: .init(width: texture.width, height: texture.height),
                                           time: self.currentCmTime) { (context, buff) in
                    let ci = CIImage(mtlTexture: texture, options: nil)!
                    let ci2 = ci.transformed(by: .init(scaleX: 1, y: -1))
                        .transformed(by: .init(translationX: 0, y: CGFloat(texture.height)))
                    context.render(ci2, to: buff)
                }
                return cm
            }
            .compactMap { [weak self] (cmSampleBuffer: CMSampleBuffer) -> CMSampleBuffer? in
                guard let self = self else { return nil }
                return cmSampleBuffer
            }
            .sink { [weak self] (buff: CMSampleBuffer) in
                self?.sampleBufferDisplayLayer.enqueue(buff)
            }
            .store(in: &cancellables)
    }
    
    var currentCmTime: CMTime {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        let currentNanoSec = Double(tsc) * Double(tb.numer) / Double(tb.denom)
        return CMTime(value: CMTimeValue(currentNanoSec),
                      timescale: 1_000_000_000,
                      flags: .init(rawValue: 3),
                      epoch: 0)
    }
}

struct SampleBufferDisplayViewRepresentable: CPViewRepresentable {
    let sampleBufferDisplayView = SampleBufferDisplayView(frame: .zero)

    public init(textureStream: AnyPublisher<MTLTexture, Never>) {
        sampleBufferDisplayView.setup(textureStream: textureStream)
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
