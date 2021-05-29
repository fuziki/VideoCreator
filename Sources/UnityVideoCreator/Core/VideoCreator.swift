//
//  VideoCreator.swift
//  Example
//
//  Created by fuziki on 2019/08/06.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import AVFoundation

public class VideoCreator {
    public struct VideoConfig {
        public var codec: AVVideoCodecType
        public var width: Int
        public var height: Int
        public init(codec: AVVideoCodecType, width: Int, height: Int) {
            self.codec = codec
            self.width = width
            self.height = height
        }
    }
    
    public struct AudioConfig {
        public var format: AudioFormatID
        public var channel: Int
        public var samplingRate: Float
        public var bitRate: Int
        public init(format: AudioFormatID, channel: Int, samplingRate: Float, bitRate: Int) {
            self.format = format
            self.channel = channel
            self.samplingRate = samplingRate
            self.bitRate = bitRate
        }
    }
    
    private var assetWriter: AVAssetWriter
    private var videoAssetWriterInput: AVAssetWriterInput
    private var audioAssetWriterInput: AVAssetWriterInput
    
    private var offset: CMTime? = nil
    public var nowTime: CMTime? {
        guard let offset = self.offset else {
            return nil
        }
        return CMTimeSubtract(self.cmTimeSec, offset)
    }
    
    public init?(url: String, videoConfig: VideoConfig, audioConfig: AudioConfig) {
        guard let assetWriter = try? AVAssetWriter(outputURL: URL(fileURLWithPath: url), fileType: AVFileType.mov) else {
            print("failed to create asset writter")
            return nil
        }
        self.assetWriter = assetWriter
        
        let videoConfigs: [String: Any] = [AVVideoCodecKey : videoConfig.codec,
                                           AVVideoWidthKey : videoConfig.width,
                                           AVVideoHeightKey : videoConfig.height]
        videoAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoConfigs)
        videoAssetWriterInput.expectsMediaDataInRealTime = true
        assetWriter.add(videoAssetWriterInput)
        
        let audioConfigs: [String: Any] = [AVFormatIDKey : audioConfig.format,
                                           AVNumberOfChannelsKey : audioConfig.channel,
                                           AVSampleRateKey : audioConfig.samplingRate,
                                           AVEncoderBitRateKey : audioConfig.bitRate]
        audioAssetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioConfigs)
        audioAssetWriterInput.expectsMediaDataInRealTime = true
        assetWriter.add(audioAssetWriterInput)
    }
    
    public func write(sample: CMSampleBuffer, isVideo: Bool) {
        guard CMSampleBufferDataIsReady(sample),
            assetWriter.status != .failed else {
                print("ready: \(CMSampleBufferDataIsReady(sample)), status: \(assetWriter.status)")
                return
        }

        if assetWriter.status == .unknown {
            let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: startTime)
            
            offset = CMTimeSubtract(self.cmTimeSec, startTime)
            print("assetWriter startWriting")
        }

        let input = isVideo ? videoAssetWriterInput: audioAssetWriterInput
        if input.isReadyForMoreMediaData {
            let ret = input.append(sample)
            if !ret {
                print("input append sample, ret: \(ret), isVideo: \(isVideo), error: \(assetWriter.error)")
            }
        } else {
            print("input is NOT ReadyForMoreMediaData, isVideo: \(isVideo)")
        }
    }
    
    public func finish(completionHandler: @escaping () -> Void){
        assetWriter.finishWriting(completionHandler: completionHandler)
    }
    
    private var timeSec: Double {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        return Double(tsc) * Double(tb.numer) / Double(tb.denom) / 1000000000.0
    }
    
    private var cmTimeSec: CMTime {
        return CMTime(value: CMTimeValue(Int(timeSec * 1000000000)),
                      timescale: 1000000000,
                      flags: .init(rawValue: 3),
                      epoch: 0)
    }
}
