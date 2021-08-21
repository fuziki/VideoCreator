//
//  HLSCreatorService.swift
//  HlsExample
//
//  Created by fuziki on 2021/08/09.
//

import MetalKit
import UnityVideoCreator

protocol HlsCreatorService: AnyObject {
    var onSegmentData: ((Data) -> Void)? { get set }
    func setup(width: Int, height: Int, segmentDurationMicroSec: Int)
    func write(texture: MTLTexture)
}

class DefaultHlsCreatorService: HlsCreatorService {
    public static let shared = DefaultHlsCreatorService()

    public var onSegmentData: ((Data) -> Void)?

    public func setup(width: Int, height: Int, segmentDurationMicroSec: Int) {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("tmpDri")
        // swiftlint:disable force_try
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        let tmpUrl = tmpDir.absoluteString as NSString
        UnityMediaCreator_initAsHlsWithNoAudio(tmpUrl.utf8String, "h264", Int64(width), Int64(height), Int64(segmentDurationMicroSec))

        UnityMediaCreator_setOnSegmentData { (data: UnsafePointer<UInt8>, len: Int64) in
            var res = Data(count: Int(len))
            res.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
                let dst: UnsafeMutableRawPointer? = ptr.baseAddress
                memcpy(dst, data, Int(len))
            }
            DefaultHlsCreatorService.shared.onSegmentData?(res)
        }
    }

    private var sentFirstFrame: Bool = false

    public func write(texture: MTLTexture) {
        let time = Int64(timeSec * 1_000_000)
        if !sentFirstFrame {
            sentFirstFrame = true
            UnityMediaCreator_start(time)
        }
        UnityMediaCreator_writeVideo(Unmanaged.passUnretained(texture).toOpaque(), time)
    }

    private var timeSec: Double {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        return Double(tsc) * Double(tb.numer) / Double(tb.denom) / 1000000000.0
    }
}
