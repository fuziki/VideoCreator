//
//  File.swift
//
//
//  Created by fuziki on 2021/06/13.
//

import AVFoundation
import XCTest
@testable import UnityVideoCreator

final class InitMediaWriterTest: XCTestCase {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("hoge", isDirectory: false)

    let h264 = AnyVideoWriterInput(codec: .h264, width: 1920, height: 1080, expectsMediaDataInRealTime: true)
    let h265 = AnyVideoWriterInput(codec: .hevcWithAlpha, width: 1920, height: 1080, expectsMediaDataInRealTime: true)
    let aac = AacAudioWriterInput(channel: 1, samplingRate: 48000, bitRate: 128000, expectsMediaDataInRealTime: true)
    let liner = WavLinerAudioWriterInput(channel: 1, samplingRate: 48000, bitDepth: 16, expectsMediaDataInRealTime: true)

    func testCorrectConfig() {

        let configs: [MediaWriterConfig] = [
            MovMediaWriterConfig(url: url, video: h264, audio: nil, contentIdentifier: ""),
            MovMediaWriterConfig(url: url, video: h265, audio: nil, contentIdentifier: ""),
            MovMediaWriterConfig(url: url, video: h264, audio: aac, contentIdentifier: ""),
            MovMediaWriterConfig(url: url, video: h265, audio: aac, contentIdentifier: ""),
            WavMediaWriterConfig(url: url, audio: liner)
        ]

        for config in configs {
            XCTAssertNoThrow(try MediaWriter(url: config.url, fileType: config.fileType, inputConfigs: config.inputConfigs, contentIdentifier: config.contentIdentifier, segmentDuration: nil))
        }
    }

}
