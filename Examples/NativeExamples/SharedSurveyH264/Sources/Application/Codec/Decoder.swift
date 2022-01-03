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

class Decoder {
    private var session: VTDecompressionSession?

    public let decodedSampleBuffer: AnyPublisher<CMSampleBuffer, Never>
    private let decodedSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    public init() {
        decodedSampleBuffer = decodedSampleBufferSubject.eraseToAnyPublisher()
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
        print("decoded frame")
        decodedSampleBufferSubject.send(res)
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
