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
        let earliestPresentationTimeStampStr = String(format: "%.3f", earliestPresentationTimeStamp.seconds)
        let durationStr = String(format: "%.3f", duration.seconds)
        return "\(description) trackID: \(trackID), mediaType: \(mediaType), earliestPresentationTimeStamp: \(earliestPresentationTimeStampStr), duration: \(durationStr), firstVideoSampleInformation: \( firstVideoSampleInformation?.debugMessage ?? "nil")"
    }
}

@available(iOS 14.0, macOS 11.0, *)
extension AVAssetSegmentReportSampleInformation {
    var debugMessage: String {
        let presentationTimeStampStr = String(format: "%.3f", presentationTimeStamp.seconds)
        return "\(description) presentationTimeStamp: \(presentationTimeStampStr), offset: \(offset), length: \(length), isSyncSample \(isSyncSample)"
    }
}
