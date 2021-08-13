//
//  OutputMocks.swift
//  
//
//  Created by fuziki on 2021/06/19.
//

import AVFoundation
import Foundation
@testable import UnityVideoCreator

class MediaCreatorProviderMock: MediaCreatorProvider {
    var makeHandler: ((MediaWriterConfig) throws -> (MediaCreator))?
    func make(config: MediaWriterConfig) throws -> MediaCreator {
        return try! makeHandler!(config)
    }
}

class MediaCreatorMock: MediaCreator {
    init() { }
    init(isRecording: Bool = false) {
        self.isRecording = isRecording
    }
    
    var deinitHandler: (() -> Void)?
    deinit {
        deinitHandler?()
    }

    private(set) var isRecordingSetCallCount = 0
    var isRecording: Bool = false { didSet { isRecordingSetCallCount += 1 } }

    private(set) var startCallCount = 0
    var startHandler: ((Int) throws -> ())?
    func start(microSec: Int) throws  {
        startCallCount += 1
        if let startHandler = startHandler {
            try startHandler(microSec)
        }
        
    }

    private(set) var startTimeCallCount = 0
    var startTimeHandler: ((CMTime) throws -> ())?
    func start(time: CMTime) throws  {
        startTimeCallCount += 1
        if let startTimeHandler = startTimeHandler {
            try startTimeHandler(time)
        }
        
    }

    private(set) var finishCallCount = 0
    var finishHandler: ((@escaping () -> Void) -> ())?
    func finish(completionHandler: @escaping () -> Void)  {
        finishCallCount += 1
        if let finishHandler = finishHandler {
            finishHandler(completionHandler)
        }
        
    }

    private(set) var writeCallCount = 0
    var writeHandler: ((MTLTexture, Int) throws -> ())?
    func write(texture: MTLTexture, microSec: Int) throws  {
        writeCallCount += 1
        if let writeHandler = writeHandler {
            try writeHandler(texture, microSec)
        }
        
    }

    private(set) var writeTextureCallCount = 0
    var writeTextureHandler: ((MTLTexture, CMTime) throws -> ())?
    func write(texture: MTLTexture, time: CMTime) throws  {
        writeTextureCallCount += 1
        if let writeTextureHandler = writeTextureHandler {
            try writeTextureHandler(texture, time)
        }
        
    }

    private(set) var writePcmCallCount = 0
    var writePcmHandler: ((AVAudioPCMBuffer, Int) throws -> ())?
    func write(pcm: AVAudioPCMBuffer, microSec: Int) throws  {
        writePcmCallCount += 1
        if let writePcmHandler = writePcmHandler {
            try writePcmHandler(pcm, microSec)
        }
        
    }

    private(set) var writePcmTimeCallCount = 0
    var writePcmTimeHandler: ((AVAudioPCMBuffer, CMTime) throws -> ())?
    func write(pcm: AVAudioPCMBuffer, time: CMTime) throws  {
        writePcmTimeCallCount += 1
        if let writePcmTimeHandler = writePcmTimeHandler {
            try writePcmTimeHandler(pcm, time)
        }
        
    }
    
    func setOnSegmentData(handler: @escaping (Data) -> Void) {
        
    }
}
