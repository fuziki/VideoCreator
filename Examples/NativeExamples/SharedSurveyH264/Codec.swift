//
//  Codec.swift
//  NativeExamples
//
//  Created by fuziki on 2021/12/26.
//

import CoreMedia
import CoreVideo
import Combine
import Foundation
import VideoToolbox

class Encoder {
    var session: VTCompressionSession?
    
    let encodedSampleBuffer: AnyPublisher<CMSampleBuffer, Never>
    private let encodedSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    init() {
        encodedSampleBuffer = encodedSampleBufferSubject.eraseToAnyPublisher()
    }
    
    func setup(width: Int32, height: Int32) {
        var session: VTCompressionSession?
        let encoderSpecification: CFDictionary? = nil
        let imageBufferAttributes: CFDictionary? = nil
        VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                   width: width,
                                   height: height,
                                   codecType: kCMVideoCodecType_H264,
                                   encoderSpecification: encoderSpecification,
                                   imageBufferAttributes: imageBufferAttributes,
                                   compressedDataAllocator: nil,
                                   outputCallback: outputCallback,
                                   refcon: Unmanaged.passUnretained(self).toOpaque(),
                                   compressionSessionOut: &session)
        self.session = session
    }
    
    
    let outputCallback: VTCompressionOutputCallback = { (outputCallbackRefCon: UnsafeMutableRawPointer?,
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
    
    func callback(outputCallbackRefCon: UnsafeMutableRawPointer?,
                  sourceFrameRefCon: UnsafeMutableRawPointer?,
                  status: OSStatus,
                  infoFlags: VTEncodeInfoFlags,
                  sampleBuffer: CMSampleBuffer?) {
        print("encoded infoFlags: \(infoFlags == .asynchronous ? ".asynchronous" : ".frameDropped")")
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
    
    func encode(imageBuffer: CVImageBuffer, presentationTimeStamp: CMTime, duration: CMTime) {
        var flags: VTEncodeInfoFlags = []
        if session == nil {
            setup(width: Int32(CVPixelBufferGetWidth(imageBuffer)), height: Int32(CVPixelBufferGetHeight(imageBuffer)))
        }
        guard let session = session else { return }
        print("encode frame")
        VTCompressionSessionEncodeFrame(session,
                                        imageBuffer: imageBuffer,
                                        presentationTimeStamp: presentationTimeStamp,
                                        duration: duration,
                                        frameProperties: nil,
                                        sourceFrameRefcon: nil,
                                        infoFlagsOut: &flags)
    }
}

class Decoder {
    let decoded: AnyPublisher<CMSampleBuffer, Never>
    private let decodedSubject = PassthroughSubject<CMSampleBuffer, Never>()

    init() {
        decoded = decodedSubject.eraseToAnyPublisher()
    }
    
    func decode(data: CMSampleBuffer) {
        decodedSubject.send(data)
    }
}
