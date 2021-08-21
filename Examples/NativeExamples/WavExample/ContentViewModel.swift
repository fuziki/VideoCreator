//
//  ContentViewModel.swift
//  WavExample
//
//  Created by fuziki on 2021/06/19.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI
import UnityVideoCreator

class ContentViewModel: ObservableObject {
    public var label: String {
        return recording ? "recording" : "prepare"
    }

    @Published private var recording: Bool = false

    private let tmpUrl: NSString
    private var sentFirstFrame: Bool = false
    private let audioEngine = AudioEngineService()

    private var cancellables: Set<AnyCancellable> = []
    init() {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        self.tmpUrl = tmpDir.appendingPathComponent("tmp.wav", isDirectory: false).absoluteString as NSString
        audioEngine.onBufferPublisher.sink { [weak self] (buffer: AVAudioPCMBuffer, timeSec: Double) in
            self?.write(buffer: buffer, timeSec: timeSec)
        }.store(in: &cancellables)
    }

    private func write(buffer: AVAudioPCMBuffer, timeSec: Double) {
        let microSec = Int64(timeSec * 1_000_000)

        if !sentFirstFrame {
            sentFirstFrame = true
            UnityMediaCreator_start(microSec)
        }
        if !UnityMediaCreator_isRecording() {
            return
        }

        UnityMediaCreator_writeAudio(buffer.floatChannelData!.pointee,
                                     Int64(buffer.frameLength),
                                     microSec)
    }

    public func tapButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.recording.toggle()
            self.audioEngine.stop()
            if self.recording {
                UnityMediaCreator_initAsWav(self.tmpUrl.utf8String!, 1, Float(AppConfig.fs), 32)
                self.sentFirstFrame = false
                self.audioEngine.start()
            } else {
                UnityMediaCreator_finishSync()
                self.audioEngine.play(url: URL(string: self.tmpUrl as String)!)
            }
        }
    }
}
