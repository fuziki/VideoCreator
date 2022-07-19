//
//  SampleBufferVideoFactory.swift
//  NativeExamples
//
//  Created by fuziki on 2021/12/26.
//

import CoreImage
import CoreMedia
import Foundation

class PixelBufferFactory {
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
#if !os(macOS)
        let options: [String: Any]? = [ kCVPixelBufferIOSurfacePropertiesKey: [:] ] as [String: Any]
#else
        let options: [String: Any]? = nil
#endif
        let status1 = CVPixelBufferCreate(nil,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
                                          options as CFDictionary?,
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
        var sampleTiming = CMSampleTimingInfo()
        sampleTiming.presentationTimeStamp = time
        _ = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                               imageBuffer: buff,
                                               dataReady: true,
                                               makeDataReadyCallback: nil,
                                               refcon: nil,
                                               formatDescription: desc,
                                               sampleTiming: &sampleTiming,
                                               sampleBufferOut: &tmp)
        CVPixelBufferUnlockBaseAddress(buff, CVPixelBufferLockFlags(rawValue: 0))
        return tmp
    }

    func make(size: CGSize, render: (CIContext, CVPixelBuffer) -> Void) -> CVPixelBuffer? {
        if width != Int(size.width) || height != Int(size.height) {
            makePixelBuffer(width: Int(size.width), height: Int(size.height))
        }
        guard let buff = pixelBuffer else {
            return nil
        }
        render(context, buff)
        return buff
    }
}
