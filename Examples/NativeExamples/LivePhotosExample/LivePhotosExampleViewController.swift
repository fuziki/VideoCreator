//
//  LivePhotosExampleViewController.swift
//  LivePhotosExample
//
//  Created by fuziki on 2021/08/15.
//

import Combine
import SharedGameView
import UnityVideoCreator
import UIKit

class LivePhotosExampleViewController: UIViewController {
    
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var sharedGameView: SharedGameView!
    
    private let timeProvider: TimeProvider = DefaultTimeProvider()
    
    private var tmpUrl: NSString!
    private var uuid: NSString = ""
    
    private var isRecording: Bool = false
    private var sentFirstFrame: Bool = false

    private var cancellables: Set<AnyCancellable> = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        self.tmpUrl = tmpDir.appendingPathComponent("tmp.mov", isDirectory: false).absoluteString as NSString
        
        sharedGameView.lastNextDrawableTexturePublisher.sink { [weak self] (texture: MTLTexture) in
            self?.write(texture: texture)
        }.store(in: &cancellables)
    }

    @IBAction func takeLivePhotos(_ sender: Any) {
        if isRecording { return }
        isRecording = true
        sentFirstFrame = false
        
        uuid = UUID().uuidString as NSString        
        let size = sharedGameView.drawableSize
        UnityMediaCreator_initAsMovWithNoAudio(tmpUrl?.utf8String, "h264",
                                               Int64(size.width), Int64(size.height),
                                               uuid.utf8String)
        
        indicatorLabel.text = "Recording..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.finish()
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        guard let texture = sharedGameView.lastNextDrawableTexture else {
            return
        }
        UnityMediaSaver_saveImage(Unmanaged.passUnretained(texture).toOpaque(), "png")
        if indicatorLabel.text?.hasPrefix("Saved!!!") == true {
            indicatorLabel.text! += "!"
        } else {
            indicatorLabel.text = "Saved!!!"
        }
    }
    
    private func finish() {
        defer {
            isRecording = false
        }
        UnityMediaCreator_finishSync()
        guard let texture = sharedGameView.lastNextDrawableTexture else {
            return
        }
        UnityMediaSaver_saveLivePhotos(Unmanaged.passUnretained(texture).toOpaque(),
                                       uuid.utf8String,
                                       tmpUrl?.utf8String)
        indicatorLabel.text = "Saved!!!"
    }
    
    private func write(texture: MTLTexture) {
        if !isRecording { return }
        
        let time = Int64(timeProvider.currentMicroSec)
        if !sentFirstFrame {
            sentFirstFrame = true
            UnityMediaCreator_start(time)
        }

        if !UnityMediaCreator_isRecording() { return }
        
        UnityMediaCreator_writeVideo(Unmanaged.passUnretained(texture).toOpaque(), time)
    }
}
