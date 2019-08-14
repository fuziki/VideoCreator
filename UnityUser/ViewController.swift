//
//  ViewController.swift
//  UnityUser
//
//  Created by fuziki on 2019/08/12.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import VideoCreator
import MetalKit
import Metal

class ViewController: UIViewController {
    
    var captureSession: AVCaptureSession!
    var videoDevice: AVCaptureDevice!
    var audioDevice: AVCaptureDevice!
    var videoCreator: VideoCreator? = nil
    var videoConfig: VideoCreator.VideoConfig!
    var audioConfig: VideoCreator.AudioConfig!
    
    var tmpFilePath: String!
    
    var isRecording: Bool = false
    
    static var sharedMtlDevive: MTLDevice = MTLCreateSystemDefaultDevice()!
    
    @IBOutlet weak var checkView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            try AVAudioSession.sharedInstance().setPreferredSampleRate(44100.0)
            try AVAudioSession.sharedInstance().setPreferredInputNumberOfChannels(1)
        } catch let error {
            print("failed init aduio session error: \(error)")
        }
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080
        guard let videoDevice = AVCaptureDevice.default(for: AVMediaType.video),
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
                print("failed init capture device")
                return
        }
        
        videoConfig = VideoCreator.VideoConfig(codec: AVVideoCodecType.h264,
                                               width: 1920,
                                               height: 1080)
        audioConfig = VideoCreator.AudioConfig(format: kAudioFormatMPEG4AAC,
                                               channel: 1,
                                               samplingRate: 44100.0,
                                               bitRate: 128000)
        
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
        
        self.videoDevice = videoDevice
        self.audioDevice = audioDevice
        
        captureSession.addInput(videoInput)
        captureSession.addInput(audioInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings
            = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)] as [String : Any]
        captureSession.addOutput(videoOutput)
        
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(audioOutput)
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        checkView.layer.addSublayer(videoLayer)
        
        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        self.tmpFilePath = "\(dir)/tmpVideo.mov"
        
        let loader = MTKTextureLoader(device: ViewController.sharedMtlDevive)
        //         testTex: MTLTexture
        do {
            let ui: UIImage = UIImage(named: "test.jpeg")!
            let cg: CGImage = ui.cgImage!
            testTex = try loader.newTexture(cgImage: cg, options: nil)
        } catch let error {
            print("erro: \(error)")
            return
        }
        
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, ViewController.sharedMtlDevive, nil, &textureCache)
        capturedImageTextureCache = textureCache
        
        self.makeVideoCreator()
        self.captureSession.startRunning()
        print("start running")
    }
    
    var capturedImageTextureCache: CVMetalTextureCache!
    
    @IBAction func start(_ sender: Any) {
        print("start recording")
        isRecording = true
    }
    
    @IBAction func pause(_ sender: Any) {
        
    }
    
    @IBAction func resume(_ sender: Any) {
        
    }
    
    @IBAction func stop(_ sender: Any) {
        print("stop recording")
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
    
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        
        return texture
    }
    
    var videoFactory = CMSampleBuffer.VideoFactory(width: 1920, height: 1080)
    
    var testTex: MTLTexture!
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !self.isRecording {
            return
        }
        
        if output is AVCaptureAudioDataOutput {
            self.videoCreator?.write(sample: sampleBuffer, isVideo: false)
            return
        }
        
        guard let tex = sampleBuffer.toMtlTexture,
            let nowTime = videoCreator?.nowTime,
            let buff = videoFactory.make(mtlTexture: tex, time: nowTime) else {
            return
        }
        self.videoCreator?.write(sample: buff, isVideo: true)
    }
}


extension CMSampleBuffer {
    class VideoFactory {
        let context = CIContext()
        var width: Int!
        var height: Int!
        var pixelBuffer: CVPixelBuffer? = nil
        var formatDescription: CMVideoFormatDescription? = nil
        init(width: Int, height: Int) {
            makePixelBuffer(width: width, height: height)
        }

        private func makePixelBuffer(width: Int, height: Int) {
            self.width = width
            self.height = height
            let options = [ kCVPixelBufferIOSurfacePropertiesKey: [:] ] as [String : Any]
            let status1 = CVPixelBufferCreate(nil,
                                              width,
                                              height,
                                              kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                              options as CFDictionary,
                                              &pixelBuffer)
            guard status1 == noErr, let buff = pixelBuffer else {
                return
            }
            let status2 = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                       imageBuffer: buff,
                                                                       formatDescriptionOut: &formatDescription)
            guard status2 == noErr else {
                return
            }
        }

        func make(mtlTexture: MTLTexture, time: CMTime) -> CMSampleBuffer? {
            if width != mtlTexture.width || height != mtlTexture.height {
                makePixelBuffer(width: mtlTexture.width, height: mtlTexture.height)
            }
            guard let ci = CIImage(mtlTexture: mtlTexture, options: nil),
                let buff = pixelBuffer,
                let desc = formatDescription else {
                return nil
            }
            CVPixelBufferLockBaseAddress(buff, CVPixelBufferLockFlags(rawValue: 0))
            context.render(ci, to: buff)
            var tmp: CMSampleBuffer? = nil
            var sampleTiming = CMSampleTimingInfo()
            sampleTiming.presentationTimeStamp = time
            let _ = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                       imageBuffer: buff,
                                                       dataReady: true,
                                                       makeDataReadyCallback: nil,
                                                       refcon: nil,
                                                       formatDescription: desc,
                                                       sampleTiming: &sampleTiming,
                                                       sampleBufferOut: &tmp)
            CVPixelBufferUnlockBaseAddress(buff, CVPixelBufferLockFlags(rawValue: 0))
            return tmp
        }
    }
}

extension CMSampleBuffer {
    var toMtlTexture: MTLTexture? {
        guard let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(self) else {
            print("failed CMSampleBufferGetImageBuffer")
            return nil
        }
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let inputImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(mtlDevice: ViewController.sharedMtlDevive)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = .unknown
        let toTexture = ViewController.sharedMtlDevive.makeTexture(descriptor: textureDescriptor)
        context.render(inputImage, to: toTexture!, commandBuffer: nil, bounds: inputImage.extent, colorSpace: colorSpace)
        return toTexture!
    }
}
