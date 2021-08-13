//
//  File.swift
//  
//
//  Created by fuziki on 2021/08/13.
//

import AVFoundation
import Foundation

@available(iOS 14.0, macOS 11.0, *)
extension AVAssetSegmentTrackReport {
    var debugMessage: String {
        return "\(description) trackID: \(trackID), mediaType: \(mediaType), earliestPresentationTimeStamp: \(earliestPresentationTimeStamp.seconds), duration: \(duration.seconds), firstVideoSampleInformation: \( firstVideoSampleInformation?.debugMessage ?? "nil")"
    }
}

@available(iOS 14.0, macOS 11.0, *)
extension AVAssetSegmentReportSampleInformation {
    var debugMessage: String {
        return "\(description) presentationTimeStamp: \(presentationTimeStamp.seconds), offset: \(offset), length: \(length), isSyncSample \(isSyncSample)"
    }
}
