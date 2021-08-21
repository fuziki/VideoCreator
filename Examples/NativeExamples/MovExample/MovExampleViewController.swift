//
//  MovExampleViewController.swift
//  MovExample
//
//  Created by fuziki on 2021/08/15.
//

import AVFoundation
import Combine
import SharedGameView
import UnityVideoCreator
import UIKit

class MovExampleViewController: UIViewController {

    @IBOutlet weak var sharedGameView: SharedGameView!
    @IBOutlet weak var saveWithAudioSwitch: UISwitch!
    @IBOutlet weak var button: UIButton!

    private let timeProvider: TimeProvider = DefaultTimeProvider()
    private let audioEngine = AudioEngineService()

    private var tmpUrl: NSString!

    private var isRecording: Bool = false
    private var sentFirstFrame: Bool = false

    private var cancellables: Set<AnyCancellable> = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        // swiftlint:disable force_try
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        self.tmpUrl = tmpDir.appendingPathComponent("tmp.mov", isDirectory: false).absoluteString as NSString

        sharedGameView.lastNextDrawableTexturePublisher.sink { [weak self] (texture: MTLTexture) in
            self?.write(texture: texture)
        }.store(in: &cancellables)

        audioEngine.onBufferPublisher.sink { [weak self] (buffer: AVAudioPCMBuffer, timeSec: Double) in
            self?.write(buffer: buffer, timeSec: timeSec)
        }.store(in: &cancellables)
    }

    @IBAction func buttonAction(_ sender: Any) {
        if isRecording {
            finish()
        } else {
            start()
        }
    }

    private func start() {
        sentFirstFrame = false
        let size = sharedGameView.drawableSize
        if saveWithAudioSwitch.isOn {
            UnityMediaCreator_initAsMovWithAudio(tmpUrl?.utf8String, "h264",
                                                 Int64(size.width), Int64(size.height),
                                                 1, 48_000, "")
            audioEngine.start()
        } else {
            UnityMediaCreator_initAsMovWithNoAudio(tmpUrl?.utf8String, "h264",
                                                   Int64(size.width), Int64(size.height),
                                                   "")
        }
        button.setTitle("Stop Recording", for: .normal)
        isRecording = true
    }

    private func finish() {
        audioEngine.stop()
        UnityMediaCreator_finishSync()
        UnityMediaSaver_saveVideo(tmpUrl?.utf8String)
        button.setTitle("Start Recording", for: .normal)
        isRecording = false
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

    private func write(buffer: AVAudioPCMBuffer, timeSec: Double) {
        let microSec = Int64(timeSec * 1_000_000)
        if !UnityMediaCreator_isRecording() {
            return
        }
        UnityMediaCreator_writeAudio(buffer.floatChannelData!.pointee,
                                     Int64(buffer.frameLength),
                                     microSec)
    }
}
