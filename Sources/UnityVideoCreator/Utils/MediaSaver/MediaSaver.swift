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

@_cdecl("UnityMediaSaver_saveLivePhotos")
public func UnityMediaSaver_saveLivePhotos(_ texturePtr: UnsafeRawPointer?,
                                           _ contentIdentifier: UnsafePointer<CChar>?,
                                           _ url: UnsafePointer<CChar>?) {
    let brideged: MTLTexture = __bridge(texturePtr!)
    let srgb = brideged.makeTextureView(pixelFormat: .rgba8Unorm_srgb)!
    let ci = CIImage(mtlTexture: srgb, options: [:])!
    let context = CIContext()
    let contentIdentifier = String(cString: contentIdentifier!)
    let properties: [CFString : Any] = [kCGImagePropertyMakerAppleDictionary: ["17": contentIdentifier]]
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

