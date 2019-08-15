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
    
    @IBOutlet weak var checkView: UIView!
    
    var testTex: MTLTexture!
    
    var unity: VideoCreatorUnity!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return
        }
        let tmpFilePath = "\(dir)/tmpVideo.mov"
        print("tmpfile: \(tmpFilePath)")
        
        let device = MTLCreateSystemDefaultDevice()!
        let loader = MTKTextureLoader(device: device)
        do {
            let ui: UIImage = UIImage(named: "test.jpeg")!
            let cg: CGImage = ui.cgImage!
            testTex = try loader.newTexture(cgImage: cg, options: nil)
        } catch let error {
            print("erro: \(error)")
            return
        }
        
        unity = VideoCreatorUnity(tmpFilePath: tmpFilePath,
                                  enableMic: true,
                                  videoWidth: testTex.width,
                                  videoHeight: testTex.height)
        
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true, block: { [weak self] (timer: Timer) in
            if let me = self, me.unity.isRecording {
                me.unity.append(mtlTexture: me.testTex)
            }
        })
    }
    
    @IBAction func start(_ sender: Any) {
        print("start recording")
        unity.startRecording()
    }
    
    @IBAction func pause(_ sender: Any) {
        
    }
    
    @IBAction func resume(_ sender: Any) {
        
    }
    
    @IBAction func stop(_ sender: Any) {
        print("stop recording")
        unity.finishRecording()
    }
}
