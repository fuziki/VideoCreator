//
//  GameViewController.swift
//  HlsExample
//
//  Created by fuziki on 2021/08/09.
//

import UIKit
import MetalKit
import UnityVideoCreator

// Our iOS specific view controller
class GameViewController: UIViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

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
        mtkView.framebufferOnly = false

        guard let newRenderer = Renderer(metalKitView: mtkView) else {
            print("Renderer cannot be initialized")
            return
        }

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
    }
    
    private var link: CADisplayLink?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("start recording")
        let tex = mtkView.currentDrawable!.texture
        print("init \(tex.width) x \(tex.height)")

        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        let tmpUrl = tmpDir.absoluteString as NSString
        UnityMediaCreator_initAsHlsWithNoAudio(tmpUrl.utf8String, "h264", Int64(tex.width), Int64(tex.height), 1_000_000)
        
        UnityMediaCreator_setOnSegmentData { (data: UnsafePointer<UInt8>, len: Int64) in
            print("on segment data: \(len), \(data)")
        }
        
        link = CADisplayLink(target: self, selector: #selector(self.update))
        link?.preferredFramesPerSecond = 30
        link?.add(to: RunLoop.main, forMode: .common)
        link?.isPaused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.link?.isPaused = false
        }
    }
    
    private var sentFirstFrame: Bool = false
    @objc private func update(displayLink: CADisplayLink) {
        let time = Int64(timeSec * 1_000_000)
        if !sentFirstFrame {
            sentFirstFrame = true
            UnityMediaCreator_start(time)
        }
        let tex = mtkView.currentDrawable!.texture
        UnityMediaCreator_writeVideo(Unmanaged.passUnretained(tex).toOpaque(), time)
    }

    private var timeSec: Double {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        return Double(tsc) * Double(tb.numer) / Double(tb.denom) / 1000000000.0
    }
}
