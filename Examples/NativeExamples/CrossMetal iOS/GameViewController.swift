//
//  GameViewController.swift
//  CrossMetal iOS
//
//  Created by fuziki on 2021/06/06.
//

import UIKit
import MetalKit
import UnityVideoCreator
import Foundation

// Our iOS specific view controller
class GameViewController: UIViewController {

    var renderer: Renderer!
    
    @IBOutlet weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .gray

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }

        mtkView.device = defaultDevice
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.layer.isOpaque = false
        mtkView.framebufferOnly = false
        mtkView.preferredFramesPerSecond = 60

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        
        link = CADisplayLink(target: self, selector: #selector(self.update))
        link?.preferredFramesPerSecond = 30
        link?.add(to: RunLoop.main, forMode: .common)
        link?.isPaused = true
        
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        self.tmpUrl = tmpDir.appendingPathComponent("tmp.mov", isDirectory: false).absoluteString as NSString
    }
    
    var link: CADisplayLink?
    var vc: UnsafePointer<VideoCreatorUnity>?
    var recording: Bool = false
    var tmpUrl: NSString?
    var sentFirstFrame: Bool = false
    
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
    
    @IBAction func actButton(_ sender: Any) {
// check uiimage if need
//        let tex = mtkView.currentDrawable!.texture
//        let ci = CIImage(mtlTexture: tex, options: nil)!
//        let context = CIContext()
//        let cg = context.createCGImage(ci, from: ci.extent)!
//        let ui = UIImage(cgImage: cg)

        if recording {
            recording = false
            UnityMediaCreator_finishSync()
            UnityMediaSaver_saveVideo(tmpUrl?.utf8String)
            link!.isPaused = true
            sentFirstFrame = false
            print("finish recording")
        } else {
            print("start recording")
            UnityMediaCreator_initAsMovWithNoAudio(tmpUrl?.utf8String,
                                                   "h264",
                                                   Int64(view.frame.width),
                                                   Int64(view.frame.height))
            recording = true
            link!.isPaused = false
        }
    }
    
    private var timeSec: Double {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        return Double(tsc) * Double(tb.numer) / Double(tb.denom) / 1000000000.0
    }
}
