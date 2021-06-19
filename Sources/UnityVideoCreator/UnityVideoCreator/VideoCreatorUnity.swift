//
//  VideoCreatorUnity.swift
//  UnityUser
//
//  Created by fuziki on 2019/08/14.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import AVFoundation
import AssetsLibrary

public enum VideoCreatorVideoCodec: String {
    case h264
    case hevcWithAlpha
    var avVideoCodecType: AVVideoCodecType {
        switch self {
        case .h264:
            return .h264
        case .hevcWithAlpha:
            return .hevcWithAlpha
        }
    }
}

public class VideoCreatorUnity: NSObject {
    private var creator: MyVideoCreatorUnity!
    public init(tmpFilePath: String, enableMic: Bool, videoWidth: Int, videoHeight: Int, videoCodec: String) {
        super.init()
        let videoCodec = VideoCreatorVideoCodec(rawValue: videoCodec) ?? .h264
        creator = MyVideoCreatorUnity(tmpFilePath: tmpFilePath,
                                      enableMic: enableMic,
                                      videoWidth: videoWidth,
                                      videoHeight: videoHeight,
                                      videoCodec: videoCodec)
    }

    public var isRecording: Bool {
        return creator.isRecording
    }

    public func startRecording() {
        creator.startRecording()
    }
    
    public func append(mtlTexture: MTLTexture) {
        creator.append(mtlTexture: mtlTexture)
    }
    
    public func finishRecording() {
        creator.finishRecording()
    }
}

private class MyVideoCreatorUnity: NSObject {
    private var captureSession: AVCaptureSession? = nil
    private var audioDevice: AVCaptureDevice? = nil

    private var videoCreator: VideoCreator? = nil
    
    private var videoConfig: VideoCreator.VideoConfig!
    private var audioConfig: VideoCreator.AudioConfig!
    
    private var tmpFilePath: String!
    public var isRecording: Bool {
        return _isRecording
    }
    private var _isRecording: Bool = false
    private var videoFactory: SampleBufferVideoFactory!
    
    public init(tmpFilePath: String, enableMic: Bool, videoWidth: Int, videoHeight: Int, videoCodec: VideoCreatorVideoCodec) {
        super.init()
        print("VideoCreator init with tmpFilePath: \(tmpFilePath), \(enableMic), \(videoWidth), \(videoHeight)")
        self.tmpFilePath = tmpFilePath
        videoFactory = SampleBufferVideoFactory(width: videoWidth, height: videoHeight)
        videoConfig = VideoCreator.VideoConfig(codec: videoCodec.avVideoCodecType,
                                               width: videoWidth,
                                               height: videoHeight)
        audioConfig = VideoCreator.AudioConfig(format: kAudioFormatMPEG4AAC,
                                               channel: 1,
                                               samplingRate: 48000,
                                               bitRate: 128000)
        self.startMic()
        self.makeVideoCreator()
    }
    
    private func startMic() {
        do {
            try AVAudioSession.sharedInstance().setPreferredSampleRate(48000)
//            try AVAudioSession.sharedInstance().setPreferredInputNumberOfChannels(1)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch let error {
            print("failed init aduio session error: \(error)")
        }
        captureSession = AVCaptureSession()
        guard let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
                print("failed init capture device")
                return
        }
        self.audioDevice = audioDevice
        captureSession?.addInput(audioInput)
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession?.addOutput(audioOutput)
        self.captureSession?.startRunning()
    }

    private func makeVideoCreator() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.tmpFilePath) {
            do {
                try fileManager.removeItem(atPath: self.tmpFilePath)
            } catch let error {
                print("makeVideoCreator \(error)")
            }
        }
        self.videoCreator = VideoCreator(url: self.tmpFilePath, videoConfig: self.videoConfig, audioConfig: self.audioConfig)
    }
    
    public func startRecording() {
        self._isRecording = true
    }
    
    public func append(mtlTexture: MTLTexture) {
        guard let nowTime = videoCreator?.nowTime,
            let buff = videoFactory.make(mtlTexture: mtlTexture, time: nowTime) else {
            return
        }
        self.videoCreator?.write(sample: buff, isVideo: true)
    }
    
    public func finishRecording() {
        if !self.isRecording {
            return
        }
        self.videoCreator?.finish(completionHandler: { [weak self] in
            guard let self = self else { return }
            UnityMediaSaver_saveVideo((self.tmpFilePath as NSString).utf8String!)
            self.videoCreator = nil
            self.makeVideoCreator()
        })
        self._isRecording = false
    }
}

extension MyVideoCreatorUnity: AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        if self.isRecording,
            output is AVCaptureAudioDataOutput {
            self.videoCreator?.write(sample: sampleBuffer, isVideo: false)
        }
    }
}
