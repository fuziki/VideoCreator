//
//  CMSampleBuffer+Extension.swift
//  UnityUser
//
//  Created by fuziki on 2019/08/14.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import AVFoundation
import CoreImage

class SampleBufferVideoFactory {
    let context = CIContext()
    var width: Int!
    var height: Int!
    var pixelBuffer: CVPixelBuffer? = nil
    var formatDescription: CMVideoFormatDescription? = nil
    init(width: Int, height: Int) {
        makePixelBuffer(width: width, height: height)
    }
    
    private func makePixelBuffer(width: Int, height: Int) {
        self.width = width
        self.height = height
        let options = [ kCVPixelBufferIOSurfacePropertiesKey: [:] ] as [String : Any]
        let status1 = CVPixelBufferCreate(nil,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
//                                              kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
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
    
    func make(mtlTexture: MTLTexture, time: CMTime) -> CMSampleBuffer? {
        if width != mtlTexture.width || height != mtlTexture.height {
            makePixelBuffer(width: mtlTexture.width, height: mtlTexture.height)
        }
        guard let ci = CIImage(mtlTexture: mtlTexture, options: nil),
            let buff = pixelBuffer,
            let desc = formatDescription else {
                return nil
        }
        CVPixelBufferLockBaseAddress(buff, CVPixelBufferLockFlags(rawValue: 0))
        context.render(ci, to: buff)
        var tmp: CMSampleBuffer? = nil
        var sampleTiming = CMSampleTimingInfo()
        sampleTiming.presentationTimeStamp = time
        let _ = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
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
}

class SampleBufferAudioFactory {
    func make(pcmBuffer: AVAudioPCMBuffer, time: CMTime) -> CMSampleBuffer? {
        let audioBufferList: AudioBufferList = pcmBuffer.audioBufferList.pointee
        var blockBuffer: CMBlockBuffer?
        _ = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                               memoryBlock: audioBufferList.mBuffers.mData,
                                               blockLength: Int(audioBufferList.mBuffers.mDataByteSize),
                                               blockAllocator: kCFAllocatorNull,
                                               customBlockSource: nil,
                                               offsetToData: 0,
                                               dataLength: Int(audioBufferList.mBuffers.mDataByteSize),
                                               flags: 0,
                                               blockBufferOut: &blockBuffer)
        let formatDescription: CMAudioFormatDescription = pcmBuffer.format.formatDescription
        var sampleBuffer: CMSampleBuffer?
        _ = CMAudioSampleBufferCreateWithPacketDescriptions(allocator: kCFAllocatorDefault,
                                                            dataBuffer: blockBuffer,
                                                            dataReady: true,
                                                            makeDataReadyCallback: nil,
                                                            refcon: nil,
                                                            formatDescription: formatDescription,
                                                            sampleCount: CMItemCount(pcmBuffer.frameLength),
                                                            presentationTimeStamp: time,
                                                            packetDescriptions: nil,
                                                            sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }
}
