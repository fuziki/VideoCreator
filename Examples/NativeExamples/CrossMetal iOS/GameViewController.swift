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
        
        self.view.layoutIfNeeded()
        
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        let tmpFile = tmpDir.appendingPathComponent("tmp.mov", isDirectory: false).path as NSString
        
        vc = videoCreator_initWithVideoCodec(tmpFile.utf8String!, true,
                                             Int64(view.frame.width), Int64(view.frame.height),
                                             "hevcWithAlpha")
    }
    
    var link: CADisplayLink?
    var vc: UnsafePointer<VideoCreatorUnity>?
    var recording: Bool = false
    
    @objc private func update(displayLink: CADisplayLink) {
        if !recording { return }
        
        if !videoCreator_isRecording(vc) { return }
        
        print("append texture")
        
        let tex = mtkView.currentDrawable!.texture
        videoCreator_append(vc, Unmanaged.passUnretained(tex).toOpaque())
    }
    
    @IBAction func actButton(_ sender: Any) {
        print("button: \(recording)")

// check uiimage if need
//        let tex = mtkView.currentDrawable!.texture
//        let ci = CIImage(mtlTexture: tex, options: nil)!
//        let context = CIContext()
//        let cg = context.createCGImage(ci, from: ci.extent)!
//        let ui = UIImage(cgImage: cg)

        if recording {
            recording = false
            videoCreator_finishRecording(vc)
            link!.isPaused = true
        } else {
            recording = true
            videoCreator_startRecording(vc)
            link!.isPaused = false
        }
        
        
    }
    
}
