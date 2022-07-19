//
//  CdeclH264Streamer.swift
//  
//
//  Created by fuziki on 2022/01/03.
//

import CoreMedia
import CoreImage
import Combine
import Foundation
import Metal

// swiftlint:disable identifier_name superfluous_disable_command

@_cdecl("H264Streamer_Start")
public func H264Streamer_Start(_ url: UnsafePointer<CChar>?, _ width: Int64, _ height: Int64) {
    let url = String(cString: url!)
    H264Streamer.shared = H264Streamer(url: url, width: Int(width), height: Int(height))
}

@_cdecl("H264Streamer_Enqueue")
public func H264Streamer_Enqueue(_ texturePtr: UnsafeRawPointer?, _ microSec: Int64) {
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
    H264Streamer.shared?.enqueue(texture: srgb, microSec: Int(microSec))
}

@_cdecl("H264Streamer_Close")
public func H264Streamer_Close() {
    H264Streamer.shared?.close()
    H264Streamer.shared = nil
}

class H264Streamer {
    public static var shared: H264Streamer?

    private let encoder: Encoder
    private let client: Client
    private let pixelBufferFactory: PixelBufferFactory

    private var cancellables: Set<AnyCancellable> = []
    public init(url: String, width: Int, height: Int) {
        encoder = Encoder()
        client = Client(url: url)
        pixelBufferFactory = PixelBufferFactory(width: width, height: height)

        encoder.setup(width: Int32(width), height: Int32(height))
        encoder
            .encodedSampleBuffer
            .map { EncodedFrameEntity.make(from: $0) }
            .receive(on: DispatchQueue(label: "hogehoge.fuga.hogegggggg.encoded"))
            .sink { [weak self] frameEntity in
                let b64 = EncodedFrameEntityBase64(nonBase64: frameEntity)
                let data: Data
                do {
                    data = try JSONEncoder().encode(b64)
                } catch let error {
                    print("error: \(error)")
                    return
                }
                print("data count: \(data.count)")
                self?.client.send(message: data)
            }
            .store(in: &cancellables)
    }

    public func enqueue(texture: MTLTexture, microSec: Int) {
        let imageBuffer = pixelBufferFactory.make(size: .init(width: texture.width, height: texture.height)) { (context, buff) in
                let ci = CIImage(mtlTexture: texture, options: nil)!
                context.render(ci, to: buff)
        }
        guard let ib = imageBuffer else {
            return
        }
        let scale: UInt64 = 1_000_000_000
        self.encoder.encode(imageBuffer: ib,
                            presentationTimeStamp: cmTimeFrom(microSec: microSec),
                            duration: CMTime(value: CMTimeValue(scale / UInt64(30)), timescale: CMTimeScale(scale)))
    }

    public func close() {
    }

    private func cmTimeFrom(microSec: Int) -> CMTime {
        return CMTime(value: CMTimeValue(microSec),
                      timescale: 1_000_000,
                      flags: .init(rawValue: 3),
                      epoch: 0)
    }
}
