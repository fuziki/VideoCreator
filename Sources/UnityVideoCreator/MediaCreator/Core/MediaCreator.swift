//
//  MediaCreator.swift
//  
//
//  Created by fuziki on 2021/06/13.
//

import AVFoundation
import os

protocol MediaCreator {
    var isRecording: Bool { get }
    func start(microSec: Int) throws
    func start(time: CMTime) throws
    func finish(completionHandler: @escaping () -> Void)
    func write(texture: MTLTexture, microSec: Int) throws
    func write(texture: MTLTexture, time: CMTime) throws
    func write(pcm: AVAudioPCMBuffer, microSec: Int) throws
    func write(pcm: AVAudioPCMBuffer, time: CMTime) throws
}

class DefaultMediaCreator: MediaCreator {
    
    public var isRecording: Bool = false
    
    private let writer: MediaWriter
    
    private let videoFactory: SampleBufferVideoFactory?
    private let audioFactory: SampleBufferAudioFactory = SampleBufferAudioFactory()
    
    init(config: MediaWriterConfig) throws {
        writer = try MediaWriter(url: config.url, fileType: config.fileType, inputConfigs: config.inputConfigs)
        
        if let config = config as? MovMediaWriterConfig {
            videoFactory = SampleBufferVideoFactory(width: config.video.width, height: config.video.height)
        } else {
            videoFactory = nil
        }
    }
    
    public func start(microSec: Int) throws {
        try start(time: cmTimeFrom(microSec: microSec))
        isRecording = true
    }

    public func start(time: CMTime) throws {
        try writer.start(time: time)
        isRecording = true
    }
    
    public func finish(completionHandler: @escaping () -> Void) {
        isRecording = false
        writer.finish(completionHandler: completionHandler)
    }
        
    public func write(texture: MTLTexture, microSec: Int) throws {
        try write(texture: texture, time: cmTimeFrom(microSec: microSec))
    }
    
    public func write(texture: MTLTexture, time: CMTime) throws {
        guard let buff = videoFactory?.make(mtlTexture: texture, time: time) else {
            return
        }
        try writer.write(mediaType: .video, sample: buff)
    }
    
    public func write(pcm: AVAudioPCMBuffer, microSec: Int) throws {
        try write(pcm: pcm, time: cmTimeFrom(microSec: microSec))
    }

    public func write(pcm: AVAudioPCMBuffer, time: CMTime) throws {
        guard let buff = audioFactory.make(pcmBuffer: pcm, time: time) else {
            os_log(.error, log: .default, "failed make sample buffer from pcm")
            return
        }
        try writer.write(mediaType: .audio, sample: buff)
    }
    
    private func cmTimeFrom(microSec: Int) -> CMTime {
        return CMTime(value: CMTimeValue(microSec * 1_000),
                      timescale: 1_000_000_000,
                      flags: .init(rawValue: 3),
                      epoch: 0)
    }
}
