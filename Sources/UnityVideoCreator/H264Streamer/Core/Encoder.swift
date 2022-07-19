//
//  Encoder.swift
//  NativeExamples
//
//  Created by fuziki on 2022/01/01.
//

import CoreMedia
import CoreVideo
import Combine
import Foundation
import VideoToolbox

class Encoder {
    private var session: VTCompressionSession?

    public let encodedSampleBuffer: AnyPublisher<CMSampleBuffer, Never>
    private let encodedSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    private var cancellables: Set<AnyCancellable> = []
    public init() {
        encodedSampleBuffer = encodedSampleBufferSubject.eraseToAnyPublisher()
    }

    public func setup(width: Int32, height: Int32) {
        var session: VTCompressionSession?
        let encoderSpecification: CFDictionary? = nil
        let imageBufferAttributes: CFDictionary? = nil
        let res = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                             width: width,
                                             height: height,
                                             codecType: kCMVideoCodecType_H264,
                                             encoderSpecification: encoderSpecification,
                                             imageBufferAttributes: imageBufferAttributes,
                                             compressedDataAllocator: nil,
                                             outputCallback: outputCallback,
                                             refcon: Unmanaged.passUnretained(self).toOpaque(),
                                             compressionSessionOut: &session)
        if res != noErr {
            print("failed create VTCompressionSession: \(res)")
            return
        }
        VTSessionSetProperty(session!, key: kVTCompressionPropertyKey_AverageBitRate, value: 1_000_000 as CFTypeRef)
        self.session = session
    }

    // swiftlint:disable closure_parameter_position
    private let outputCallback: VTCompressionOutputCallback = { (outputCallbackRefCon: UnsafeMutableRawPointer?,
                                                                 sourceFrameRefCon: UnsafeMutableRawPointer?,
                                                                 status: OSStatus,
                                                                 infoFlags: VTEncodeInfoFlags,
                                                                 sampleBuffer: CMSampleBuffer?) in
        guard let outputCallbackRefCon = outputCallbackRefCon else { return }
        let refcon = Unmanaged<Encoder>.fromOpaque(outputCallbackRefCon).takeUnretainedValue()
        refcon.callback(outputCallbackRefCon: outputCallbackRefCon,
                        sourceFrameRefCon: sourceFrameRefCon,
                        status: status,
                        infoFlags: infoFlags,
                        sampleBuffer: sampleBuffer)
    }

    private func callback(outputCallbackRefCon: UnsafeMutableRawPointer?,
                          sourceFrameRefCon: UnsafeMutableRawPointer?,
                          status: OSStatus,
                          infoFlags: VTEncodeInfoFlags,
                          sampleBuffer: CMSampleBuffer?) {
        let infoFlags = infoFlags == .asynchronous ? ".asynchronous" : ".frameDropped"
        let size = (sampleBuffer?.dataBuffer?.dataLength).flatMap { Float($0) / 1_000 } ?? -1
        print("encoded infoFlags: \(infoFlags), size: \(size)KB")
        guard status == noErr else {
            print("encode error: \(status)")
            return
        }
        guard let sampleBuffer = sampleBuffer else {
            print("encode error: no sampleBuffer")
            return
        }
        encodedSampleBufferSubject.send(sampleBuffer)
    }

    public func encode(imageBuffer: CVImageBuffer, presentationTimeStamp: CMTime, duration: CMTime) {
        if session == nil {
            setup(width: Int32(CVPixelBufferGetWidth(imageBuffer)), height: Int32(CVPixelBufferGetHeight(imageBuffer)))
        }
        guard let session = session else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let mb = Float(bytesPerRow * height / 1_000) / 1_000
        print("encode frame size: \(mb)MB, w: \(width), h: \(height), bpp: \(bytesPerRow / width)")
        var infoFlagsOut: VTEncodeInfoFlags = []
        let res = VTCompressionSessionEncodeFrame(session,
                                                  imageBuffer: imageBuffer,
                                                  presentationTimeStamp: presentationTimeStamp,
                                                  duration: duration,
                                                  frameProperties: nil,
                                                  sourceFrameRefcon: nil,
                                                  infoFlagsOut: &infoFlagsOut)
        if res != noErr {
            print("faield encode frame: \(res)")
        }
    }
}
