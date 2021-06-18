//
//  UnityMediaCreator.swift
//  
//
//  Created by fuziki on 2021/06/13.
//

import AssetsLibrary
import AVFoundation
import Foundation
import Metal

class UnityMediaCreator {
    public static var shared: UnityMediaCreator = UnityMediaCreator()
    
    private var url: URL? = nil
    private var samplingRate: Float? = nil
    private var channel: Int? = nil
    private var creator: MediaCreator? = nil

    public func initAsMovWithAudio(url: String, codec: String, width: Int, height: Int, channel: Int, samplingRate: Float) {
        finishSync()
        let url = URL(string: url)!
        clean(url: url)
        self.url = url
        let video = AnyVideoWriterInput(codec: codec == "hevcWithAlpha" ? .hevcWithAlpha : .h264,
                                        width: width,
                                        height: height,
                                        expectsMediaDataInRealTime: true)
        let audio = AacAudioWriterInput(channel: channel,
                                        samplingRate: samplingRate,
                                        bitRate: 128000,
                                        expectsMediaDataInRealTime: true)
        let config = MovMediaWriterConfig(url: url, video: video, audio: audio)
        self.samplingRate = samplingRate
        self.channel = channel
        self.creator = try! MediaCreator(config: config)
    }
    
    public func initAsMovWithNoAudio(url: String, codec: String, width: Int, height: Int) {
        finishSync()
        let url = URL(string: url)!
        clean(url: url)
        self.url = url
        let video = AnyVideoWriterInput(codec: codec == "hevcWithAlpha" ? .hevcWithAlpha : .h264,
                                        width: width,
                                        height: height,
                                        expectsMediaDataInRealTime: true)
        let config = MovMediaWriterConfig(url: url, video: video, audio: nil)
        self.creator = try! MediaCreator(config: config)
    }
    
    public func initAsWav(url: String, channel: Int, samplingRate: Float, bitDepth: Int) {
        finishSync()
        let url = URL(string: url)!
        clean(url: url)
        self.url = url
        let audio = WavLinerAudioWriterInput(channel: channel,
                                             samplingRate: samplingRate,
                                             bitDepth: bitDepth,
                                             expectsMediaDataInRealTime: true)
        let config = WavMediaWriterConfig(url: url, audio: audio)
        self.samplingRate = samplingRate
        self.channel = channel
        self.creator = try! MediaCreator(config: config)
    }
    
    private func clean(url: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch let error {
                print("makeVideoCreator \(error)")
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
//            ALAssetsLibrary()
//                .writeVideoAtPath(toSavedPhotosAlbum: self.url!) { [weak self] (url: URL?, error: Error?) in
//                    print("url: \(String(describing: url)), error: \(String(describing: error))")
//                }
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
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frame))!
        memcpy(buffer.floatChannelData![0], pcm, MemoryLayout<Float>.size * frame)
        try! creator?.write(pcm: buffer, microSec: microSec)
    }
}
