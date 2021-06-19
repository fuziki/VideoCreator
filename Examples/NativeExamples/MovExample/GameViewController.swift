//
//  GameViewController.swift
//  MovExample
//
//  Created by fuziki on 2021/06/20.
//

import AVFoundation
import Combine
import MetalKit
import UIKit
import UnityVideoCreator

// Our iOS specific view controller
class GameViewController: UIViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    private var cancellables: Set<AnyCancellable> = []
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        self.mtkView = mtkView

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        
        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.black

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        
        mtkView.framebufferOnly = false
        
        link = CADisplayLink(target: self, selector: #selector(self.update))
        link?.preferredFramesPerSecond = 30
        link?.add(to: RunLoop.main, forMode: .common)
        link?.isPaused = true
        
        audioEngine.onBufferPublisher.sink { [weak self] (buffer: AVAudioPCMBuffer, timeSec: Double) in
            self?.write(buffer: buffer, timeSec: timeSec)
        }.store(in: &cancellables)
        
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        self.tmpUrl = tmpDir.appendingPathComponent("tmp.mov", isDirectory: false).absoluteString as NSString
    }
    
    var link: CADisplayLink?
    var recording: Bool = false
    var tmpUrl: NSString?
    var sentFirstFrame: Bool = false
    let audioEngine = AudioEngineService()
    
    @IBAction func onTapButton(_ sender: Any) {
        recording.toggle()
        if recording {
            print("start recording")
            UnityMediaCreator_initAsMovWithAudio(tmpUrl?.utf8String,
                                                 "h264",
                                                 Int64(view.frame.width),
                                                 Int64(view.frame.height), 1, Float(AppConfig.fs))
            sentFirstFrame = false
            link!.isPaused = false
            audioEngine.start()
        } else {
            link!.isPaused = true
            audioEngine.stop()
            UnityMediaCreator_finishSync()
            UnityMediaSaver_saveVideo(tmpUrl?.utf8String)
            print("finish recording")
        }        
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        if !recording { return }

        let time = Int64(timeSec * 1_000_000)
        if !sentFirstFrame {
            sentFirstFrame = true
            UnityMediaCreator_start(time)
        }

        if !UnityMediaCreator_isRecording() { return }

        print("append texture")

        let tex = mtkView.currentDrawable!.texture
        UnityMediaCreator_writeVideo(Unmanaged.passUnretained(tex).toOpaque(), time)
    }
    
    private func write(buffer: AVAudioPCMBuffer, timeSec: Double) {
        let microSec = Int64(timeSec * 1_000_000)
        
        print("timeSec: \(self.timeSec), \(timeSec)")
        
        if !UnityMediaCreator_isRecording() {
            return
        }
        
        UnityMediaCreator_writeAudio(buffer.floatChannelData!.pointee,
                                     Int64(buffer.frameLength),
                                     microSec)
    }
    
    private var timeSec: Double {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        return Double(tsc) * Double(tb.numer) / Double(tb.denom) / 1000000000.0
    }
}
