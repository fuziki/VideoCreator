//
//  MediaCreator.swift
//  
//
//  Created by fuziki on 2021/06/13.
//

import AVFoundation

class MediaCreator {
    
    public var isRecording = false
    
    private let writer: MediaWriter
    
    private let videoFactory: CMSampleBuffer.VideoFactory?
    private let audioFactory: CMSampleBufferAudioFactory = CMSampleBufferAudioFactory()
    
    init(config: MediaWriterConfig) throws {
        writer = try MediaWriter(url: config.url, fileType: config.fileType, inputConfigs: config.inputConfigs)
        
        if let config = config as? MovMediaWriterConfig {
            videoFactory = CMSampleBuffer.VideoFactory(width: config.video.width, height: config.video.height)
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
    
    public func finish(completionHandler: @escaping () -> Void){
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
