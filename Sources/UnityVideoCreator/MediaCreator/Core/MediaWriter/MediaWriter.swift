//
//  MediaWriter.swift
//  
//
//  Created by fuziki on 2021/06/13.
//

import AVFoundation
import os

enum MediaWriterError: Error {
    case unknown
    case dataIsNotReady
    case assetWriterStatusIsFailed
    case noInput
}

class MediaWriter {
    struct InputConfig {
        let mediaType: AVMediaType
        let outputSettings: [String : Any]?
        let expectsMediaDataInRealTime: Bool
    }
    
    private let assetWriter: AVAssetWriter
    
    init(url: URL,
         fileType: AVFileType,
         inputConfigs: [InputConfig]) throws {
        
        let assetWriter = try AVAssetWriter(outputURL: url, fileType: fileType)
        self.assetWriter = assetWriter
        
        for config in inputConfigs {
            let input = AVAssetWriterInput(mediaType: config.mediaType, outputSettings: config.outputSettings)
            input.expectsMediaDataInRealTime = config.expectsMediaDataInRealTime
            assetWriter.add(input)
        }
    }
    
    public func start(time: CMTime) throws {
        let success = assetWriter.startWriting()
        if !success {
            throw assetWriter.error ?? MediaWriterError.unknown
        }
        assetWriter.startSession(atSourceTime: time)
    }
    
    public func finish(completionHandler: @escaping () -> Void){
        assetWriter.finishWriting(completionHandler: completionHandler)
    }
    
    public func write(mediaType: AVMediaType, sample: CMSampleBuffer) throws {
        guard CMSampleBufferDataIsReady(sample) else {
            throw MediaWriterError.dataIsNotReady
        }
        guard assetWriter.status != .failed else {
            throw MediaWriterError.assetWriterStatusIsFailed
        }
        guard let input = assetWriter.inputs.filter({ $0.mediaType == mediaType }).first else {
            throw MediaWriterError.noInput
        }
        let success = input.append(sample)
        if !success {
            os_log(.error, log: .default, "failed append %@", [sample])
            throw assetWriter.error ?? MediaWriterError.unknown
        }
    }
}
