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
    
    let viewModel: GameViewModelType = GameViewModel()
    let hlsCreator: HlsCreator = HlsCreator.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("open: http://\(getIpAddress()!):8080/hello")

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

        hlsCreator.setup(width: tex.width, height: tex.height)
        hlsCreator.onSegmentData = { [weak self] (data: Data) in
            self?.viewModel.onSegmentData(data: data)
        }
        
        link = CADisplayLink(target: self, selector: #selector(self.update))
        link?.preferredFramesPerSecond = 30
        link?.add(to: RunLoop.main, forMode: .common)
        link?.isPaused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.link?.isPaused = false
        }
    }
    
    @objc private func update(displayLink: CADisplayLink) {
        let texture = mtkView.currentDrawable!.texture
        hlsCreator.write(texture: texture)
    }
}
