//
//  SampleBufferAudioFactory+Extension.swift
//  UnityUser
//
//  Created by fuziki on 2019/08/14.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import AVFoundation

internal class SampleBufferAudioFactory {
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
