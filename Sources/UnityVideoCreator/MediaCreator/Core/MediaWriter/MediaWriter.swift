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

class MediaWriter: NSObject {
    public struct InputConfig {
        let mediaType: AVMediaType
        let outputSettings: [String : Any]?
        let expectsMediaDataInRealTime: Bool
    }
    
    // MARK:- Outputs
    public var onSegmentData: ((Data) -> Void)?
    
    // MARK:- Properties
    private let assetWriter: AVAssetWriter
    private var metadataAdaptor: AVAssetWriterInputMetadataAdaptor?
    private var startTime: CMTime?
    private var latestTime: CMTime?
    
    init(url: URL,
         fileType: AVFileType,
         inputConfigs: [InputConfig],
         contentIdentifier: String,
         segmentDuration: CMTime?) throws {
        
        let assetWriter: AVAssetWriter
        if #available(iOS 14.0, *),
           segmentDuration != nil {
            // setup as hls
            assetWriter = AVAssetWriter(contentType: UTType(fileType.rawValue)!)
        } else {
            // setup as mov or wav
            assetWriter = try AVAssetWriter(outputURL: url, fileType: fileType)
        }
        self.assetWriter = assetWriter
        super.init()

        for config in inputConfigs {
            let input = AVAssetWriterInput(mediaType: config.mediaType, outputSettings: config.outputSettings)
            input.expectsMediaDataInRealTime = config.expectsMediaDataInRealTime
            assetWriter.add(input)
        }
        
        // setup as live photos
        if contentIdentifier.count > 0 {
            assetWriter.metadata = [makeContentIdentifierMetadataItem(identifier: contentIdentifier)]
            self.metadataAdaptor = makeStillImageTimeMetadataAdaptor()
            assetWriter.add(metadataAdaptor!.assetWriterInput)
        }
        
        // setup as hls
        if #available(iOS 14.0, *),
           let segmentDuration = segmentDuration {
            assetWriter.outputFileTypeProfile = .mpeg4AppleHLS
            assetWriter.preferredOutputSegmentInterval = segmentDuration
            assetWriter.initialSegmentStartTime = .zero
            assetWriter.delegate = self
        }
    }
    
    // MARK:- Inputs
    public func start(time: CMTime) throws {
        let success = assetWriter.startWriting()
        if !success {
            throw assetWriter.error ?? MediaWriterError.unknown
        }
        assetWriter.startSession(atSourceTime: time)
        
        self.startTime = time
    }
    
    public func finish(completionHandler: @escaping () -> Void){
        if let metadataAdaptor = self.metadataAdaptor,
           let startTime = self.startTime,
           let latestTime = self.latestTime {
            let timeRange = CMTimeRange(start: startTime, end: latestTime)
            metadataAdaptor.append(AVTimedMetadataGroup(items: [makeStillImageTimeMetadataItem()],
                                                        timeRange: timeRange))
        }
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
        self.latestTime = CMSampleBufferGetPresentationTimeStamp(sample)
    }

    // MARK:- privates
    private func makeContentIdentifierMetadataItem(identifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = AVMetadataKey.quickTimeMetadataKeyContentIdentifier as NSString
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = identifier as NSString
        item.dataType = kCMMetadataBaseDataType_UTF8 as String
        return item
    }

    private func makeStillImageTimeMetadataItem() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = "com.apple.quicktime.still-image-time" as NSString
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = 0 as NSNumber
        item.dataType = kCMMetadataBaseDataType_SInt8 as String
        return item
    }

    private func makeStillImageTimeMetadataAdaptor() -> AVAssetWriterInputMetadataAdaptor {
        let spec : NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier: "mdta/com.apple.quicktime.still-image-time",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType: kCMMetadataBaseDataType_SInt8
        ]
        var desc : CMFormatDescription? = nil
        CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault,
                                                                    metadataType: kCMMetadataFormatType_Boxed,
                                                                    metadataSpecifications: [spec] as CFArray,
                                                                    formatDescriptionOut: &desc)
        let input = AVAssetWriterInput(mediaType: .metadata,
                                       outputSettings: nil,
                                       sourceFormatHint: desc)
        return AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
    }
}

@available(iOS 14.0, *)
extension MediaWriter: AVAssetWriterDelegate {
    func assetWriter(_ writer: AVAssetWriter,
                     didOutputSegmentData segmentData: Data,
                     segmentType: AVAssetSegmentType,
                     segmentReport: AVAssetSegmentReport?) {
        self.onSegmentData?(segmentData)
    }
}
