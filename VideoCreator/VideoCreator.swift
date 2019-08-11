//
//  VideoCreator.swift
//  Example
//
//  Created by fuziki on 2019/08/06.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import AssetsLibrary
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
    
    public init?(url: URL, videoConfig: VideoConfig, audioConfig: AudioConfig) {
        guard let assetWriter = try? AVAssetWriter(outputURL: url, fileType: AVFileType.mov) else {
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
            return
        }

        if assetWriter.status == .unknown {
            let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: startTime)
        }

        let input = isVideo ? videoAssetWriterInput: audioAssetWriterInput
        if input.isReadyForMoreMediaData {
            input.append(sample)
        }
    }
    
    public func finish(completionHandler: @escaping () -> Void){
        assetWriter.finishWriting(completionHandler: completionHandler)
    }
}
