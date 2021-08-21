//
//  AudioEngineService.swift
//  WavExample
//
//  Created by fuziki on 2021/06/20.
//

import AVFoundation
import Combine

class AudioEngineService {
    private let onBuffer = PassthroughSubject<(buffer: AVAudioPCMBuffer, timeSec: Double), Never>()
    public var onBufferPublisher: AnyPublisher<(buffer: AVAudioPCMBuffer, timeSec: Double), Never> {
        return onBuffer.eraseToAnyPublisher()
    }

    private var engine: AVAudioEngine?

    public func start() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setPreferredSampleRate(AppConfig.fs)
            try session.setActive(true, options: [])
        } catch let error {
            print("failed init aduio session error: \(error)")
        }

        let engine = AVAudioEngine()
        self.engine = engine

        let input = engine.inputNode

        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: AppConfig.fs,
                                   channels: 1,
                                   interleaved: false)

        engine.connect(input, to: engine.mainMixerNode, format: format)
        input.volume = 0

        let bufferSize = AVAudioFrameCount(AppConfig.fs * 0.1)
        input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            let timeSec = AVAudioTime.seconds(forHostTime: time.hostTime)
            self?.onBuffer.send((buffer: buffer, timeSec: timeSec))
        }

        engine.prepare()
        // swiftlint:disable force_try
        try! engine.start()
    }

    public func play(url: URL) {

        let engine = AVAudioEngine()
        self.engine = engine

        let player = AVAudioPlayerNode()
        engine.attach(player)

        engine.connect(player, to: engine.mainMixerNode, format: nil)

        engine.prepare()
        // swiftlint:disable force_try
        try! engine.start()
        player.play()

        // swiftlint:disable force_try
        let file = try! AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        player.scheduleFile(file, at: nil, completionHandler: nil)
    }

    public func stop() {
        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        engine = nil
    }
}
