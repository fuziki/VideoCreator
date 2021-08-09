//
//  CdeclUnityMediaCreator.swift
//
//
//  Created by fuziki on 2021/06/14.
//

import Foundation
import Metal

@_cdecl("UnityMediaCreator_initAsMovWithNoAudio")
public func UnityMediaCreator_initAsMovWithNoAudio(_ url: UnsafePointer<CChar>?,
                                                   _ codec: UnsafePointer<CChar>?,
                                                   _ width: Int64,
                                                   _ height: Int64,
                                                   _ contentIdentifier: UnsafePointer<CChar>?) {
    let url = String(cString: url!)
    let codec = String(cString: codec!)
    let contentIdentifier = String(cString: contentIdentifier!)
    UnityMediaCreator.shared.initAsMovWithNoAudio(url: url,
                                                  codec: codec,
                                                  width: Int(width),
                                                  height: Int(height),
                                                  contentIdentifier: contentIdentifier)
}

@_cdecl("UnityMediaCreator_initAsMovWithAudio")
public func UnityMediaCreator_initAsMovWithAudio(_ url: UnsafePointer<CChar>?,
                                                 _ codec: UnsafePointer<CChar>?,
                                                 _ width: Int64,
                                                 _ height: Int64,
                                                 _ channel: Int64,
                                                 _ samplingRate: Float,
                                                 _ contentIdentifier: UnsafePointer<CChar>?) {
    let url = String(cString: url!)
    let codec = String(cString: codec!)
    let contentIdentifier = String(cString: contentIdentifier!)
    UnityMediaCreator.shared.initAsMovWithAudio(url: url, codec: codec, width: Int(width), height: Int(height),
                                                channel: Int(channel), samplingRate: samplingRate,
                                                contentIdentifier: contentIdentifier)
}

@_cdecl("UnityMediaCreator_initAsHlsWithNoAudio")
public func UnityMediaCreator_initAsHlsWithNoAudio(_ url: UnsafePointer<CChar>?,
                                                   _ codec: UnsafePointer<CChar>?,
                                                   _ width: Int64,
                                                   _ height: Int64,
                                                   _ segmentDurationMicroSec: Int64) {
    let url = String(cString: url!)
    let codec = String(cString: codec!)
    UnityMediaCreator.shared.initAsHlsWithNoAudio(url: url,
                                                  codec: codec,
                                                  width: Int(width),
                                                  height: Int(height),
                                                  segmentDurationMicroSec: Int(segmentDurationMicroSec))
}

@_cdecl("UnityMediaCreator_initAsWav")
public func UnityMediaCreator_initAsWav(_ url: UnsafePointer<CChar>?,
                                        _ channel: Int64,
                                        _ samplingRate: Float,
                                        _ bitDepth: Int) {
    let url = String(cString: url!)
    UnityMediaCreator.shared.initAsWav(url: url, channel: Int(channel), samplingRate: samplingRate, bitDepth: bitDepth)
}

@_cdecl("UnityMediaCreator_setOnSegmentData")
public func UnityMediaCreator_setOnSegmentData(_ handler: @escaping @convention(c) (UnsafePointer<UInt8>, Int64) -> Void) {
    UnityMediaCreator.shared.onSegmentData = { data in
        data.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) in
            let buffPtr: UnsafeBufferPointer<UInt8> = rawPtr.bindMemory(to: UInt8.self)
            let ptr = buffPtr.baseAddress!
            handler(ptr, Int64(buffPtr.count))
        }
    }
}

@_cdecl("UnityMediaCreator_start")
public func UnityMediaCreator_start(_ microSec: Int64) {
    UnityMediaCreator.shared.start(microSec: Int(microSec))
}

@_cdecl("UnityMediaCreator_finishSync")
public func UnityMediaCreator_finishSync() {
    UnityMediaCreator.shared.finishSync()
}

@_cdecl("UnityMediaCreator_isRecording")
public func UnityMediaCreator_isRecording() -> Bool {
    UnityMediaCreator.shared.isRecording
}

@_cdecl("UnityMediaCreator_writeVideo")
public func UnityMediaCreator_writeVideo(_ texturePtr: UnsafeRawPointer?, _ microSec: Int64) {
    let brideged: MTLTexture = __bridge(texturePtr!)
    let srgb = brideged.makeTextureView(pixelFormat: .rgba8Unorm_srgb)!
    UnityMediaCreator.shared.write(texture: srgb, microSec: Int(microSec))
}

@_cdecl("UnityMediaCreator_writeAudio")
public func UnityMediaCreator_writeAudio(_ pcm: UnsafePointer<Float>, _ frame: Int64, _ microSec: Int64) {
    UnityMediaCreator.shared.write(pcm: pcm, frame: Int(frame), microSec: Int(microSec))
}
