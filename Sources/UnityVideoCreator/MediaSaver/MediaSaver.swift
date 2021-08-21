//
//  File.swift
//
//
//  Created by fuziki on 2021/06/19.
//

import os
import Photos

@_cdecl("UnityMediaSaver_saveVideo")
public func UnityMediaSaver_saveVideo(_ url: UnsafePointer<CChar>?) {
    let urlStr = String(cString: url!)
    let url = URL(string: urlStr)!
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let options = PHAssetResourceCreationOptions()
        options.shouldMoveFile = true
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .video, fileURL: url, options: options)
    }
}

@_cdecl("UnityMediaSaver_saveImage")
public func UnityMediaSaver_saveImage(_ texturePtr: UnsafeRawPointer?,
                                      _ type: UnsafePointer<CChar>?) {
    let brideged: MTLTexture = __bridge(texturePtr!)
    let srgb: MTLTexture
    switch brideged.pixelFormat {
    case .rgba8Unorm:
        srgb = brideged.makeTextureView(pixelFormat: .rgba8Unorm_srgb)!
    case .bgra8Unorm:
        srgb = brideged.makeTextureView(pixelFormat: .bgra8Unorm_srgb)!
    default:
        srgb = brideged
    }
    let ci = CIImage(mtlTexture: srgb, options: [:])!
    let context = CIContext()
    let data: Data
    let type = String(cString: type!)
    switch type {
    case "jpeg", "jpg":
        data = context.jpegRepresentation(of: ci, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:])!
    case "heif":
        data = context.heifRepresentation(of: ci, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:])!
    case "png", _:
        data = context.pngRepresentation(of: ci, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:])!
    }
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .photo, data: data, options: nil)
    }
}

@_cdecl("UnityMediaSaver_saveLivePhotos")
public func UnityMediaSaver_saveLivePhotos(_ texturePtr: UnsafeRawPointer?,
                                           _ contentIdentifier: UnsafePointer<CChar>?,
                                           _ url: UnsafePointer<CChar>?) {
    let brideged: MTLTexture = __bridge(texturePtr!)
    let srgb: MTLTexture
    switch brideged.pixelFormat {
    case .rgba8Unorm:
        srgb = brideged.makeTextureView(pixelFormat: .rgba8Unorm_srgb)!
    case .bgra8Unorm:
        srgb = brideged.makeTextureView(pixelFormat: .bgra8Unorm_srgb)!
    default:
        srgb = brideged
    }
    let ci = CIImage(mtlTexture: srgb, options: [:])!
    let context = CIContext()
    let contentIdentifier = String(cString: contentIdentifier!)
    let properties: [CFString: Any] = [kCGImagePropertyMakerAppleDictionary: ["17": contentIdentifier]]
    let propertiedCi = ci.settingProperties(properties)
    let jpegData = context.jpegRepresentation(of: propertiedCi, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:])!

    let urlStr = String(cString: url!)
    let url = URL(string: urlStr)!
    do {
        try PHPhotoLibrary.shared().performChangesAndWait {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: jpegData, options: nil)
            let videoOptions = PHAssetResourceCreationOptions()
            videoOptions.shouldMoveFile = true
            request.addResource(with: .pairedVideo, fileURL: url, options: videoOptions)
        }
    } catch let error {
        os_log(.error, log: .default, "failed save as livephotos. error: %@", [error])
    }
}
