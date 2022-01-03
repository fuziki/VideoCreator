//
//  Decoder.swift
//  NativeExamples
//
//  Created by fuziki on 2021/12/26.
//

import CoreMedia
import CoreVideo
import Combine
import Foundation
import VideoToolbox

struct DecodedFrameEntity {
    let pixelBuffer: CVPixelBuffer
    let formatDescription: CMFormatDescription
    let timing: CMSampleTimingInfo
}

extension DecodedFrameEntity {
    public func toSampleBuffer() -> CMSampleBuffer? {
        var sampleTiming = self.timing
        var sampleBufferOut: CMSampleBuffer?
        let res = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: self.pixelBuffer,
                                                     dataReady: true,
                                                     makeDataReadyCallback: nil,
                                                     refcon: nil,
                                                     formatDescription: self.formatDescription,
                                                     sampleTiming: &sampleTiming,
                                                     sampleBufferOut: &sampleBufferOut)
        guard let sampleBuffer = sampleBufferOut, res == noErr else {
            print("failed to create CMSampleBuffer: \(res)")
            return nil
        }
        return sampleBuffer
    }
}

class Decoder {
    private var session: VTDecompressionSession?

    public let decodedFrameEntity: AnyPublisher<DecodedFrameEntity, Never>
    private let decodedFrameEntitySubject = PassthroughSubject<DecodedFrameEntity, Never>()

    public init() {
        decodedFrameEntity = decodedFrameEntitySubject.eraseToAnyPublisher()
    }

    private func setup(formatDescription: CMFormatDescription) {
        var session: VTDecompressionSession?
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

    private var decompressionOutputCallback: VTDecompressionOutputCallback = { (decompressionOutputRefCon: UnsafeMutableRawPointer?,
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

    private func callback(decompressionOutputRefCon: UnsafeMutableRawPointer?,
                          sourceFrameRefCon: UnsafeMutableRawPointer?,
                          status: OSStatus,
                          infoFlags: VTDecodeInfoFlags,
                          imageBuffer: CVImageBuffer?,
                          presentationTimeStamp: CMTime,
                          presentationDuration: CMTime) {
        guard let imageBuffer = imageBuffer else {
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            print("no decoded imageBuffer: \(error.localizedDescription)")
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

        let sampleTiming = CMSampleTimingInfo(duration: presentationDuration,
                                              presentationTimeStamp: presentationTimeStamp,
                                              decodeTimeStamp: .invalid)

        
        print("decoded frame")
        let entity = DecodedFrameEntity(pixelBuffer: imageBuffer, formatDescription: formatDescription, timing: sampleTiming)
        decodedFrameEntitySubject.send(entity)
    }

    public func decode(sampleBuffer: CMSampleBuffer) {
        if session == nil {
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
            print("formatDescription: \(formatDescription)")
            setup(formatDescription: formatDescription)
        }
        guard let session = session else { return }
        print("decode frame")
        let flags: VTDecodeFrameFlags = []
        var infoFlagsOut: VTDecodeInfoFlags = []
        let res = VTDecompressionSessionDecodeFrame(session,
                                                    sampleBuffer: sampleBuffer,
                                                    flags: flags,
                                                    frameRefcon: nil,
                                                    infoFlagsOut: &infoFlagsOut)
        if res != noErr {
            print("faield decode frame: \(res)")
        }
    }
}
