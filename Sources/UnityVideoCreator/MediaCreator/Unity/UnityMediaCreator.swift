//
//  UnityMediaCreator.swift
//  
//
//  Created by fuziki on 2021/06/13.
//

import AVFoundation
import Foundation
import Metal
import os

protocol MediaCreatorProvider {
    func make(config: MediaWriterConfig) throws -> MediaCreator
}

class DefualtMediaCreatorProvider: MediaCreatorProvider {
    func make(config: MediaWriterConfig) throws -> MediaCreator {
        return try DefaultMediaCreator(config: config)
    }
}

class UnityMediaCreator {
    public static var shared: UnityMediaCreator = UnityMediaCreator(provider: DefualtMediaCreatorProvider())
    
    public var onSegmentData: ((Data) -> Void)?
    
    private let provider: MediaCreatorProvider
    init(provider: MediaCreatorProvider) {
        self.provider = provider
    }
    
    private var samplingRate: Float? = nil
    private var channel: Int? = nil
    private var creator: MediaCreator? = nil

    public func initAsMovWithAudio(url: String,
                                   codec: String, width: Int, height: Int,
                                   channel: Int, samplingRate: Float,
                                   contentIdentifier: String) {
        finishSync()
        let url = URL(string: url)!
        clean(url: url)
        let video = AnyVideoWriterInput(codec: codec == "hevcWithAlpha" ? .hevcWithAlpha : .h264,
                                        width: width,
                                        height: height,
                                        expectsMediaDataInRealTime: true)
        let audio = AacAudioWriterInput(channel: channel,
                                        samplingRate: samplingRate,
                                        bitRate: 128000,
                                        expectsMediaDataInRealTime: true)
        let config = MovMediaWriterConfig(url: url, video: video, audio: audio, contentIdentifier: contentIdentifier)
        self.samplingRate = samplingRate
        self.channel = channel
        self.creator = try! provider.make(config: config)
    }
    
    public func initAsMovWithNoAudio(url: String, codec: String, width: Int, height: Int, contentIdentifier: String) {
        finishSync()
        let url = URL(string: url)!
        clean(url: url)
        let video = AnyVideoWriterInput(codec: codec == "hevcWithAlpha" ? .hevcWithAlpha : .h264,
                                        width: width,
                                        height: height,
                                        expectsMediaDataInRealTime: true)
        let config = MovMediaWriterConfig(url: url, video: video, audio: nil, contentIdentifier: contentIdentifier)
        self.creator = try! provider.make(config: config)
    }
    
    public func initAsHlsWithNoAudio(url: String, codec: String, width: Int, height: Int, segmentDurationMicroSec: Int) {
        finishSync()
        let url = URL(string: url)!
        clean(url: url)
        guard #available(iOS 14.0, *) else {
            return
        }
        let video = AnyVideoWriterInput(codec: codec == "hevcWithAlpha" ? .hevcWithAlpha : .h264,
                                        width: width,
                                        height: height,
                                        expectsMediaDataInRealTime: true)
        let config = HlsMediaWriterConfig(url: url, video: video, audio: nil, segmentDurationMicroSec: segmentDurationMicroSec)
        self.creator = try! provider.make(config: config)
        creator!.setOnSegmentData { [weak self] data in
            self?.onSegmentData?(data)
        }
    }
    
    public func initAsWav(url: String, channel: Int, samplingRate: Float, bitDepth: Int) {
        finishSync()
        let url = URL(string: url)!
        clean(url: url)
        let audio = WavLinerAudioWriterInput(channel: channel,
                                             samplingRate: samplingRate,
                                             bitDepth: bitDepth,
                                             expectsMediaDataInRealTime: true)
        let config = WavMediaWriterConfig(url: url, audio: audio)
        self.samplingRate = samplingRate
        self.channel = channel
        self.creator = try! provider.make(config: config)
    }
    
    private func clean(url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error {
                os_log(.error, log: .default, "failed clean file %@", [error])
            }
        }
    }
    
    public func start(microSec: Int) {
        try! self.creator?.start(microSec: microSec)
    }
    
    public func finishSync() {
        self.samplingRate = nil
        self.channel = nil
        if creator == nil { return }
        let semaphore = DispatchSemaphore(value: 0)
        self.creator?.finish { [weak self] in
            self?.creator = nil
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    public var isRecording: Bool {
        return creator?.isRecording ?? false
    }
    
    public func write(texture: MTLTexture, microSec: Int) {
        try! creator?.write(texture: texture, microSec: microSec)
    }
    
    public func write(pcm: UnsafePointer<Float>, frame: Int, microSec: Int) {
        guard let samplingRate = self.samplingRate,
              let channel = self.channel else {
            return
        }
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: Double(samplingRate),
                                   channels: AVAudioChannelCount(channel),
                                   interleaved: false)!
        let frameLength = AVAudioFrameCount(frame)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength)!
        buffer.frameLength = frameLength
        memcpy(buffer.floatChannelData![0], pcm, MemoryLayout<Float>.size * frame)
        try! creator?.write(pcm: buffer, microSec: microSec)
    }
}
