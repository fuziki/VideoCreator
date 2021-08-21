//
//  MediaWriterConfig.swift
//
//
//  Created by fuziki on 2021/06/13.
//

import AVFoundation
import Foundation

protocol MediaWriterConfig {
    var url: URL { get }
    var fileType: AVFileType { get }
    var inputConfigs: [MediaWriter.InputConfig] { get }
    var contentIdentifier: String { get }
    var segmentDurationMicroSec: Int? { get }
}

@available(iOS 14.0, *)
struct HlsMediaWriterConfig: MediaWriterConfig {
    let url: URL
    let fileType: AVFileType = .mp4
    let video: AnyVideoWriterInput
    let audio: AacAudioWriterInput?
    var inputConfigs: [MediaWriter.InputConfig] {
        return [video.config, audio?.config].compactMap { $0 }
    }
    let contentIdentifier: String = ""
    let segmentDurationMicroSec: Int?
}

struct MovMediaWriterConfig: MediaWriterConfig {
    let url: URL
    let fileType: AVFileType = .mov
    let video: AnyVideoWriterInput
    let audio: AacAudioWriterInput?
    var inputConfigs: [MediaWriter.InputConfig] {
        return [video.config, audio?.config].compactMap { $0 }
    }
    let contentIdentifier: String
    let segmentDurationMicroSec: Int? = nil
}

struct WavMediaWriterConfig: MediaWriterConfig {
    let url: URL
    let fileType: AVFileType = .wav
    let audio: WavLinerAudioWriterInput
    var inputConfigs: [MediaWriter.InputConfig] {
        return [audio.config]
    }
    let contentIdentifier: String = ""
    let segmentDurationMicroSec: Int? = nil
}
