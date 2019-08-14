//
//  VideoCreatorUnity.swift
//  UnityUser
//
//  Created by fuziki on 2019/08/14.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import AVFoundation
import VideoCreator
import AssetsLibrary

@objcMembers
public class VideoCreatorUnity: NSObject {
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
    private var videoFactory: CMSampleBuffer.VideoFactory!
    
    public init(tmpFilePath: String, enableMic: Bool, videoWidth: Int, videoHeight: Int) {
        super.init()
        self.tmpFilePath = tmpFilePath
        videoFactory = CMSampleBuffer.VideoFactory(width: videoWidth, height: videoHeight)
        videoConfig = VideoCreator.VideoConfig(codec: AVVideoCodecType.h264,
                                               width: videoWidth,
                                               height: videoHeight)
        audioConfig = VideoCreator.AudioConfig(format: kAudioFormatMPEG4AAC,
                                               channel: 1,
                                               samplingRate: 44100.0,
                                               bitRate: 128000)
        self.startMic()
        self.makeVideoCreator()
    }
    
    private func startMic() {
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44100.0)
            try AVAudioSession.sharedInstance().setPreferredInputNumberOfChannels(1)
        } catch let error {
            print("failed init aduio session error: \(error)")
        }
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd1920x1080
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
        let fileManager = FileManager()
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
            guard let me = self else {
                return
            }
            ALAssetsLibrary().writeVideoAtPath(toSavedPhotosAlbum: URL(fileURLWithPath: me.tmpFilePath),
                                               completionBlock: { (url: URL?, error: Error?) -> Void in
                                                print("url: \(url), error: \(error)")
                                                me.videoCreator = nil
                                                me.makeVideoCreator()
            })
        })
        self._isRecording = false
    }
    
}

extension VideoCreatorUnity: AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {

        if self.isRecording,
            output is AVCaptureAudioDataOutput {
            self.videoCreator?.write(sample: sampleBuffer, isVideo: false)
        }
    }
}
