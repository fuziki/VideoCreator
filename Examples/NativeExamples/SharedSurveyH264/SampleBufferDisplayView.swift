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
    
    var flag: Bool = false
    
    private var cancellables: Set<AnyCancellable> = []
    func setup(textureStream: AnyPublisher<MTLTexture, Never>) {
        cancellables = []
        
        let timebase = try! CMTimebase(masterClock: CMClockGetHostTimeClock())
        try! timebase.setTime(CMTime(value: 0, timescale: 1))
        try! timebase.setRate(1)
        
        sampleBufferDisplayLayer.controlTimebase = timebase
        
        textureStream
            .compactMap { [weak self] (texture: MTLTexture) -> CMSampleBuffer? in
                guard let self = self else { return nil }
                self.flag.toggle()
                if self.flag { return nil }
                if !self.sampleBufferDisplayLayer.isReadyForMoreMediaData { return nil }
                print("time: \(self.sampleBufferDisplayLayer.isReadyForMoreMediaData)")
//                let nowTime = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 60)
                let cm = self.factory.make(size: .init(width: texture.width, height: texture.height),
                                           time: self.sampleBufferDisplayLayer.timebase.time) { (context, buff) in
                    let ci = CIImage(mtlTexture: texture, options: nil)!
                    let ci2 = ci.transformed(by: .init(scaleX: 1, y: -1))
                        .transformed(by: .init(translationX: 0, y: CGFloat(texture.height)))
                    context.render(ci2, to: buff)
                }
                return cm
            }
            .sink { [weak self] (buff: CMSampleBuffer) in
                self?.sampleBufferDisplayLayer.enqueue(buff)
            }
            .store(in: &cancellables)
    }
    
    var firstTime: Double? = nil
    
    var currentCmTime: CMTime {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        var currentNanoSec = Double(tsc) * Double(tb.numer) / Double(tb.denom)
        if firstTime == nil {
            firstTime = currentNanoSec
        }
        currentNanoSec = currentNanoSec - firstTime!
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

class SampleBufferVideoFactory {
    let context = CIContext()
    var width: Int!
    var height: Int!
    var pixelBuffer: CVPixelBuffer?
    var formatDescription: CMVideoFormatDescription?
    init(width: Int, height: Int) {
        makePixelBuffer(width: width, height: height)
    }

    private func makePixelBuffer(width: Int, height: Int) {
        self.width = width
        self.height = height
        let options = [ kCVPixelBufferIOSurfacePropertiesKey: [:] ] as [String: Any]
        let status1 = CVPixelBufferCreate(nil,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
                                          options as CFDictionary,
                                          &pixelBuffer)
        guard status1 == noErr, let buff = pixelBuffer else {
            return
        }
        let status2 = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                   imageBuffer: buff,
                                                                   formatDescriptionOut: &formatDescription)
        guard status2 == noErr else {
            return
        }
    }

    func make(size: CGSize, time: CMTime, render: (CIContext, CVPixelBuffer) -> Void) -> CMSampleBuffer? {
        if width != Int(size.width) || height != Int(size.height) {
            makePixelBuffer(width: Int(size.width), height: Int(size.height))
        }
        guard let buff = pixelBuffer,
              let desc = formatDescription else {
            return nil
        }
        CVPixelBufferLockBaseAddress(buff, CVPixelBufferLockFlags(rawValue: 0))
        render(context, buff)
        var tmp: CMSampleBuffer?
//        var sampleTiming = CMSampleTimingInfo()
//        sampleTiming.presentationTimeStamp = time
        let nowTime = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 60 * 3)
        let _1_60_s = CMTime(value: 1, timescale: 60 * 3)
        var timingInfo: CMSampleTimingInfo = CMSampleTimingInfo(
                        duration: _1_60_s,
                        presentationTimeStamp: nowTime,
                        decodeTimeStamp: .invalid)
        _ = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                               imageBuffer: buff,
                                               dataReady: true,
                                               makeDataReadyCallback: nil,
                                               refcon: nil,
                                               formatDescription: desc,
                                               sampleTiming: &timingInfo,
                                               sampleBufferOut: &tmp)
        CVPixelBufferUnlockBaseAddress(buff, CVPixelBufferLockFlags(rawValue: 0))
        return tmp
    }
}
