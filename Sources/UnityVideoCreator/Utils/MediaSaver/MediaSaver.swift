//
//  File.swift
//  
//
//  Created by fuziki on 2021/06/19.
//

import Photos

@_cdecl("UnityMediaSaver_saveVideo")
public func UnityMediaSaver_saveVideo(_ url: UnsafePointer<CChar>?) {
    let urlStr = String(cString: url!)
    let url = URL(string: urlStr)!
    try! PHPhotoLibrary.shared().performChangesAndWait {
        let options = PHAssetResourceCreationOptions()
        options.shouldMoveFile = false
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: .video, fileURL: url, options: options)
    }
}
