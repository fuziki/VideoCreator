//
//  File.swift
//
//
//  Created by fuziki on 2021/06/13.
//

import AVFoundation

protocol MediaWriterInput {
    var mediaType: AVMediaType { get }
    var config: MediaWriter.InputConfig { get }
}

protocol VideoWriterInput: MediaWriterInput {
}
extension VideoWriterInput {
    var mediaType: AVMediaType { .video }
}

protocol AudioWriterInput: MediaWriterInput {
}
extension AudioWriterInput {
    var mediaType: AVMediaType { .audio }
}

struct AnyVideoWriterInput: VideoWriterInput {
    public let codec: AVVideoCodecType
    public let width: Int
    public let height: Int
    public let expectsMediaDataInRealTime: Bool
    var config: MediaWriter.InputConfig {
        let settings = [
            AVVideoCodecKey: codec,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ] as [String: Any]
        return .init(mediaType: mediaType,
                     outputSettings: settings,
                     expectsMediaDataInRealTime: expectsMediaDataInRealTime)
    }
}

struct AacAudioWriterInput: AudioWriterInput {
    public let channel: Int
    public let samplingRate: Float
    public let bitRate: Int
    public let expectsMediaDataInRealTime: Bool
    var config: MediaWriter.InputConfig {
        let settings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: channel,
            AVSampleRateKey: samplingRate,
            AVEncoderBitRateKey: bitRate
        ] as [String: Any]
        return .init(mediaType: mediaType,
                     outputSettings: settings,
                     expectsMediaDataInRealTime: expectsMediaDataInRealTime)
    }
}

struct WavLinerAudioWriterInput: AudioWriterInput {
    public let channel: Int
    public let samplingRate: Float
    public let bitDepth: Int
    public let expectsMediaDataInRealTime: Bool
    var config: MediaWriter.InputConfig {
        let settings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVNumberOfChannelsKey: channel,
            AVSampleRateKey: samplingRate,
            AVLinearPCMBitDepthKey: bitDepth,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ] as [String: Any]
        return .init(mediaType: mediaType,
                     outputSettings: settings,
                     expectsMediaDataInRealTime: expectsMediaDataInRealTime)
    }
}
