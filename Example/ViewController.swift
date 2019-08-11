//
//  ViewController.swift
//  Example
//
//  Created by fuziki on 2019/08/06.
//  Copyright © 2019 fuziki.factory. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import VideoCreator

class ViewController: UIViewController {
    
    let captureSession: AVCaptureSession = AVCaptureSession()
    let videoDevice: AVCaptureDevice? = AVCaptureDevice.default(for: AVMediaType.video)
    let audioDevice: AVCaptureDevice? = AVCaptureDevice.default(for: AVMediaType.audio)
    var videoCreator: VideoCreator? = nil

    var height: Int = 0
    var width: Int = 0
    
    var timeOffset = CMTimeMake(value: 0, timescale: 0)
    var lastAudioPts: CMTime?
    
    var isCapturing = false
    var isPaused = false
    var isDiscontinue = false
    var fileIndex = 0
    
    @IBOutlet weak var checkView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        videoDevice?.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let videoInput = try! AVCaptureDeviceInput(device: videoDevice!)
        captureSession.addInput(videoInput)
        
        let audioInput = try! AVCaptureDeviceInput(device: audioDevice!)
        captureSession.addInput(audioInput)
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings
            = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)] as [String : Any]
        captureSession.addOutput(videoDataOutput)
        
        height = videoDataOutput.videoSettings["Height"] as? Int ?? 0
        width = videoDataOutput.videoSettings["Width"] as? Int ?? 0
        
        // audio output
        let audioDataOutput = AVCaptureAudioDataOutput()
        audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(audioDataOutput)
        
        captureSession.startRunning()
        
        let videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoLayer.frame = view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        checkView.layer.addSublayer(videoLayer)
    }
    
    @IBAction func start(_ sender: Any) {
        if !self.isCapturing{
            Logger.log(message: "in")
            self.isPaused = false
            self.isDiscontinue = false
            self.isCapturing = true
            self.timeOffset = CMTimeMake(value: 0, timescale: 0)
        }
    }
    
    @IBAction func pause(_ sender: Any) {
        if self.isCapturing{
            Logger.log(message: "in")
            self.isPaused = true
            self.isDiscontinue = true
        }
    }
    
    @IBAction func resume(_ sender: Any) {
        if self.isCapturing{
            Logger.log(message: "in")
            self.isPaused = false
        }
    }
    
    @IBAction func stop(_ sender: Any) {
        if self.isCapturing{
            self.isCapturing = false
            self.videoCreator!.finish { () -> Void in
                //                Logger.log("Recording finished.")
                self.videoCreator = nil
                let assetsLib = ALAssetsLibrary()
                assetsLib.writeVideoAtPath(toSavedPhotosAlbum: self.filePathUrl(), completionBlock: {
                    (nsurl, error) -> Void in
                    Logger.log(message: "Transfer video to library finished.")
                    self.fileIndex += 1
                })
            }
        }
    }

    func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filePath : String = "\(documentsDirectory)/video\(self.fileIndex).mp4"
        return filePath
    }
    
    func filePathUrl() -> URL! {
        return URL(fileURLWithPath: self.filePath())
    }
    
    func ajustTimeStamp(sample: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count);
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: CMTimeMake(value: 0, timescale: 0),
                                                                      presentationTimeStamp: CMTimeMake(value: 0, timescale: 0),
                                                                      decodeTimeStamp: CMTimeMake(value: 0, timescale: 0)),
                                        count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, entryCount: count, arrayToFill: &info, entriesNeededOut: &count)
        
        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }
        
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(allocator: nil, sampleBuffer: sample, sampleTimingEntryCount: count, sampleTimingArray: &info, sampleBufferOut: &out);
        return out!
    }

}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !self.isCapturing || self.isPaused {
            return
        }
        
        let isVideo = output is AVCaptureVideoDataOutput
        
        if self.videoCreator == nil && !isVideo {
            let fileManager = FileManager()
            if fileManager.fileExists(atPath: self.filePath()) {
                do {
                    try fileManager.removeItem(atPath: self.filePath())
                } catch _ {
                }
            }
            
            let fmt = CMSampleBufferGetFormatDescription(sampleBuffer)
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt!)
            
            Logger.log(message: "setup video writer")
            
            self.videoCreator
                = VideoCreator(url: self.filePathUrl(),
                               videoConfig: VideoCreator.VideoConfig(codec: AVVideoCodecType.h264,
                                                                     width: self.width,
                                                                     height: self.height),
                               audioConfig: VideoCreator.AudioConfig(format: kAudioFormatMPEG4AAC,
                                                                     channel: Int(asbd!.pointee.mChannelsPerFrame),
                                                                     samplingRate: Float(asbd!.pointee.mSampleRate),
                                                                     bitRate: 128000))
    
        }
        
        if self.isDiscontinue {
            if isVideo {
                return
            }
            
            var pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            let isAudioPtsValid = self.lastAudioPts!.flags.intersection(CMTimeFlags.valid)
            if isAudioPtsValid.rawValue != 0 {
                Logger.log(message: "isAudioPtsValid is valid")
                let isTimeOffsetPtsValid = self.timeOffset.flags.intersection(CMTimeFlags.valid)
                if isTimeOffsetPtsValid.rawValue != 0 {
                    Logger.log(message: "isTimeOffsetPtsValid is valid")
                    pts = CMTimeSubtract(pts, self.timeOffset);
                }
                let offset = CMTimeSubtract(pts, self.lastAudioPts!);
                
                if (self.timeOffset.value == 0)
                {
                    Logger.log(message: "timeOffset is \(self.timeOffset.value)")
                    self.timeOffset = offset;
                }
                else
                {
                    Logger.log(message: "timeOffset is \(self.timeOffset.value)")
                    self.timeOffset = CMTimeAdd(self.timeOffset, offset);
                }
            }
            self.lastAudioPts!.flags = CMTimeFlags()
            self.isDiscontinue = false
        }
        
        var buffer = sampleBuffer
        if self.timeOffset.value > 0 {
            buffer = self.ajustTimeStamp(sample: sampleBuffer, offset: self.timeOffset)
        }
        
        if !isVideo {
            var pts = CMSampleBufferGetPresentationTimeStamp(buffer)
            let dur = CMSampleBufferGetDuration(buffer)
            if (dur.value > 0)
            {
                pts = CMTimeAdd(pts, dur)
            }
            self.lastAudioPts = pts
        }
        
        self.videoCreator?.write(sample: buffer, isVideo: isVideo)
    }
}

class Logger{
    class func log(message: String,
                   function: String = #function,
                   file: String = #file,
                   line: Int = #line) {
//        var filename = file
//        if let match = filename.rangeOfString("[^/]*$", options: .RegularExpressionSearch) {
//            filename = filename.substringWithRange(match)
//        }
        print("\(NSDate().timeIntervalSince1970):L\(line):\(function) \"\(message)\"")
    }
}
