//
//  ViewController.swift
//  ExampleMacOS
//
//  Created by fuziki on 2019/08/11.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import Cocoa
import AVFoundation
import VideoCreatorMacOS
import Foundation

class ViewController: NSViewController {
    
    var captureSession: AVCaptureSession!
    var videoDevice: AVCaptureDevice!
    var audioDevice: AVCaptureDevice!
    var videoCreator: VideoCreator? = nil
    var videoConfig: VideoCreator.VideoConfig!
    var audioConfig: VideoCreator.AudioConfig!
    
    var tmpFilePath: String!
    
    var isRecording: Bool = false
    
    @IBOutlet weak var preview: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AVCaptureDevice.requestAccess(for: .video) { audioOk in
            AVCaptureDevice.requestAccess(for: .audio) { videoOk in
                if audioOk, videoOk {
                    self.setup()
                }
            }
        }
    }
    
    func setup() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1280x720
        guard let videoDevice = AVCaptureDevice.devices(for: .video).first/*.default(for: AVMediaType.video)*/,
            let audioDevice = AVCaptureDevice.devices(for: .audio).first/*.default(for: AVMediaType.audio)*/ else {
                print("failed init capture device")
                return
        }

        do {
            try audioDevice.lockForConfiguration()
            try videoDevice.lockForConfiguration()
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            captureSession.addInput(videoInput)
            captureSession.addInput(audioInput)
        } catch let error {
            print("failed init capture device error: \(error)")
        }
        
        videoConfig = VideoCreator.VideoConfig(codec: AVVideoCodecType.h264,
                                               width: 1280,
                                               height: 720)
        audioConfig = VideoCreator.AudioConfig(format: kAudioFormatMPEG4AAC,
                                               channel: 1,
                                               samplingRate: 44100.0,
                                               bitRate: 128000)
        
        self.videoDevice = videoDevice
        self.audioDevice = audioDevice
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings
            = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)] as [String : Any]
        captureSession.addOutput(videoOutput)
        
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(audioOutput)
        
        DispatchQueue.main.async {
            let videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            videoLayer.frame = self.view.bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.preview.layer?.addSublayer(videoLayer)
        }
        
        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        self.tmpFilePath = "\(dir)/tmpVideo.mov"
        print("tmpFilePath: \(tmpFilePath!)")
        
        self.makeVideoCreator()
        self.captureSession.startRunning()
        print("start running")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func start(_ sender: Any) {
        print("start recording")
        isRecording = true
    }
    
    @IBAction func stop(_ sender: Any) {
        print("stop recording")
        if !self.isRecording {
            return
        }
        self.videoCreator?.finish(completionHandler: {
            print("complet create video")
        })
        self.isRecording = false
    }
    
    func makeVideoCreator() {
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
    
    

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !self.isRecording {
            return
        }
        self.videoCreator?.write(sample: sampleBuffer,
                                 isVideo: output is AVCaptureVideoDataOutput)
    }
}

