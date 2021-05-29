import Metal
import MetalKit

struct UnityVideoCreator {
    var text = "Hello, World!"
}

@_cdecl("videoCreator_init")
public func videoCreator_init(_ tmpFilePath: UnsafePointer<CChar>?,
                              _ enableAudio: Bool,
                              _ videoWidth: Int64,
                              _ videoHeight: Int64) -> UnsafePointer<VideoCreatorUnity> {
    let tmpFilePath = String(cString: tmpFilePath!)
    let i = VideoCreatorUnity(tmpFilePath: tmpFilePath,
                              enableMic: enableAudio,
                              videoWidth: Int(videoWidth),
                              videoHeight: Int(videoHeight))
    let pointer = UnsafeMutablePointer<VideoCreatorUnity>.allocate(capacity: 1)
    pointer.initialize(to: i)
    return UnsafePointer(pointer)
}

@_cdecl("videoCreator_isRecording")
public func videoCreator_isRecording(_ creator: UnsafePointer<VideoCreatorUnity>?) -> Bool {
    return creator!.pointee.isRecording
}

@_cdecl("videoCreator_startRecording")
public func videoCreator_startRecording(_ creator: UnsafePointer<VideoCreatorUnity>?) {
    creator!.pointee.startRecording()
}

@_cdecl("videoCreator_append")
public func videoCreator_append(_ creator: UnsafePointer<VideoCreatorUnity>?, _ texturePtr: UnsafeRawPointer?) {
    let mtlTexture: MTLTexture = __bridge(texturePtr!)
    let mtlTexture2 = mtlTexture.makeTextureView(pixelFormat: .rgba8Unorm_srgb)!
    creator!.pointee.append(mtlTexture: mtlTexture2)
}

@_cdecl("videoCreator_finishRecording")
public func videoCreator_finishRecording(_ creator: UnsafePointer<VideoCreatorUnity>?) {
    creator!.pointee.finishRecording()
}

@_cdecl("videoCreator_release")
public func videoCreator_release(_ creator: UnsafePointer<VideoCreatorUnity>?) {
    creator!.deallocate()
}

// UnsafeRawPointer == UnsafePointer<Void> == (void*)
public func __bridge<T : AnyObject>(_ ptr: UnsafeRawPointer) -> T {
    return Unmanaged.fromOpaque(ptr).takeUnretainedValue()
}
