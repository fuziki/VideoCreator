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
            print("failed create VTCompressionSession")
            return
        }
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
        if session == nil {
            setup(width: Int32(CVPixelBufferGetWidth(imageBuffer)), height: Int32(CVPixelBufferGetHeight(imageBuffer)))
        }
        guard let session = session else { return }
        print("encode frame")
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

class Decoder {
    var session: VTDecompressionSession?

    let decoded: AnyPublisher<CMSampleBuffer, Never>
    private let decodedSubject = PassthroughSubject<CMSampleBuffer, Never>()

    init() {
        decoded = decodedSubject.eraseToAnyPublisher()
    }

    func setup() {
        var session: VTDecompressionSession?
        // TODO: 何とかする
        let formatDescription: CMFormatDescription! = nil
        let decoderSpecification: CFDictionary? = nil
        let imageBufferAttributes: CFDictionary? = nil
        var outputCallback = VTDecompressionOutputCallbackRecord(decompressionOutputCallback: decompressionOutputCallback,
                                                                 decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque())
        let res = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                               formatDescription: formatDescription,
                                               decoderSpecification: decoderSpecification,
                                               imageBufferAttributes: imageBufferAttributes,
                                               outputCallback: &outputCallback,
                                               decompressionSessionOut: &session)
        if res != noErr {
            print("failed create VTDecompressionSession")
            return
        }
        self.session = session
    }

    var decompressionOutputCallback: VTDecompressionOutputCallback = { (decompressionOutputRefCon: UnsafeMutableRawPointer?,
                                                                        sourceFrameRefCon: UnsafeMutableRawPointer?,
                                                                        status: OSStatus,
                                                                        infoFlags: VTDecodeInfoFlags,
                                                                        imageBuffer: CVImageBuffer?,
                                                                        presentationTimeStamp: CMTime,
                                                                        presentationDuration: CMTime) in
        guard let decompressionOutputRefCon = decompressionOutputRefCon else { return }
        let refcon = Unmanaged<Decoder>.fromOpaque(decompressionOutputRefCon).takeUnretainedValue()
        refcon.callback(decompressionOutputRefCon: decompressionOutputRefCon,
                        sourceFrameRefCon: sourceFrameRefCon,
                        status: status,
                        infoFlags: infoFlags,
                        imageBuffer: imageBuffer,
                        presentationTimeStamp: presentationTimeStamp,
                        presentationDuration: presentationDuration)
    }

    func callback(decompressionOutputRefCon: UnsafeMutableRawPointer?,
                  sourceFrameRefCon: UnsafeMutableRawPointer?,
                  status: OSStatus,
                  infoFlags: VTDecodeInfoFlags,
                  imageBuffer: CVImageBuffer?,
                  presentationTimeStamp: CMTime,
                  presentationDuration: CMTime) {
        guard let imageBuffer = imageBuffer else {
            print("no decoded imageBuffer")
            return
        }

        var formatDescriptionOut: CMVideoFormatDescription?
        let res1 = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                imageBuffer: imageBuffer,
                                                                formatDescriptionOut: &formatDescriptionOut
        )
        guard let formatDescription = formatDescriptionOut,
              res1 == noErr else {
                  print("failed to create formatDescription: \(res1)")
                  return
              }

        var sampleTiming = CMSampleTimingInfo(duration: presentationDuration,
                                              presentationTimeStamp: presentationTimeStamp,
                                              decodeTimeStamp: .invalid)

        var sampleBuffer: CMSampleBuffer?
        let res2 = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                      imageBuffer: imageBuffer,
                                                      dataReady: true,
                                                      makeDataReadyCallback: nil,
                                                      refcon: nil,
                                                      formatDescription: formatDescription,
                                                      sampleTiming: &sampleTiming,
                                                      sampleBufferOut: &sampleBuffer)
        guard let res = sampleBuffer,
              res2 == noErr else {
                  print("failed to create CMSampleBuffer: \(res2)")
                  return
              }
        decodedSubject.send(res)
    }

    func decode(data: CMSampleBuffer) {
        if session == nil {
            setup()
        }
        guard let session = session else { return }
        print("decode frame")
        let flags: VTDecodeFrameFlags = []
        var infoFlagsOut: VTDecodeInfoFlags = []
        let res = VTDecompressionSessionDecodeFrame(session,
                                                    sampleBuffer: data,
                                                    flags: flags,
                                                    frameRefcon: nil,
                                                    infoFlagsOut: &infoFlagsOut)
        if res != noErr {
            print("faield decode frame: \(res)")
        }
    }
}
