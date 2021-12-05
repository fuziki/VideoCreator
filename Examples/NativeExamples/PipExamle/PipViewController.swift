//
//  PipViewController.swift
//  PipExamle
//
//  Created by fuziki on 2021/12/05.
//

import AVKit
import Combine
import SharedGameView
import UIKit

class SampleBufferDisplayView: UIView {
    override class var layerClass: AnyClass {
        get { return AVSampleBufferDisplayLayer.self }
    }

    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }
}

class PipViewController: UIViewController {
    
    var counter: Int = 0
    var label: UILabel = UILabel(frame: .init(origin: .zero, size: .init(width: 300, height: 200)))

    @IBOutlet weak var sampleBufferDisplayView: SampleBufferDisplayView!
    
    var pipController: AVPictureInPictureController!
    var pipPossibleObservation: NSKeyValueObservation?
    
    var sampleBufferVideoFactory = SampleBufferVideoFactory(width: 300, height: 200)

    private var cancellables: Set<AnyCancellable> = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        try! AVAudioSession.sharedInstance().setCategory(.playback)
        
        label.backgroundColor = .systemGray5
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 64)

        sampleBufferDisplayView.layer.borderColor = UIColor.gray.cgColor
        sampleBufferDisplayView.layer.borderWidth = 1

        let pipContentSource = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sampleBufferDisplayView.sampleBufferDisplayLayer,
                                                                          playbackDelegate: self)
        pipController = AVPictureInPictureController(contentSource: pipContentSource)
        
        pipController
            .publisher(for: \.isPictureInPicturePossible, options: [.initial, .new])
            .sink { possible in
                print("isPictureInPicturePossible: \(possible)")
            }
            .store(in: &cancellables)
        
        Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] (date: Date) in
                guard let self = self else { return }
                self.counter += 1
                self.label.text = "count: \(self.counter)"
                
                let imageRenderer = UIGraphicsImageRenderer(size: self.label.frame.size)
                let ui = imageRenderer.image { (context: UIGraphicsImageRendererContext) in
                    self.label.layer.render(in: context.cgContext)
                }
                let cg = ui.cgImage!
                
                let cm = self.sampleBufferVideoFactory.make(size: .init(width: cg.width, height: cg.height),
                                                            time: self.currentCmTime) { (context, buff) in
                    context.render(CIImage(cgImage: cg), to: buff)
                }!
                self.sampleBufferDisplayView.sampleBufferDisplayLayer.enqueue(cm)
            }
            .store(in: &cancellables)
    }

    @IBAction func onTapButton(_ sender: Any) {
        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            pipController.startPictureInPicture()
        }
    }
    
    var currentCmTime: CMTime {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        let currentNanoSec = Double(tsc) * Double(tb.numer) / Double(tb.denom)
        return CMTime(value: CMTimeValue(currentNanoSec),
                      timescale: 1_000_000_000,
                      flags: .init(rawValue: 3),
                      epoch: 0)
    }
}

extension PipViewController: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
    }

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .negativeInfinity, end: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {
    }
}

class SampleBufferVideoFactory {
    let context = CIContext()
    var width: Int!
    var height: Int!
    var pixelBuffer: CVPixelBuffer?
    var formatDescription: CMVideoFormatDescription?
    init(width: Int, height: Int) {
        makePixelBuffer(width: width, height: height)
    }

    private func makePixelBuffer(width: Int, height: Int) {
        self.width = width
        self.height = height
        let options = [ kCVPixelBufferIOSurfacePropertiesKey: [:] ] as [String: Any]
        let status1 = CVPixelBufferCreate(nil,
                                          width,
                                          height,
                                          kCVPixelFormatType_32BGRA,
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

    func make(size: CGSize, time: CMTime, render: (CIContext, CVPixelBuffer) -> Void) -> CMSampleBuffer? {
        if width != Int(size.width) || height != Int(size.height) {
            makePixelBuffer(width: Int(size.width), height: Int(size.height))
        }
        guard let buff = pixelBuffer,
              let desc = formatDescription else {
            return nil
        }
        CVPixelBufferLockBaseAddress(buff, CVPixelBufferLockFlags(rawValue: 0))
        render(context, buff)
        var tmp: CMSampleBuffer?
        var sampleTiming = CMSampleTimingInfo()
        sampleTiming.presentationTimeStamp = time
        _ = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
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
