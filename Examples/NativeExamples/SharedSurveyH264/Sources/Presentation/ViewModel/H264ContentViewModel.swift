//
//  H264ContentViewModel.swift
//  NativeExamples
//
//  Created by fuziki on 2022/01/01.
//

import Combine
import CoreMedia
import CoreImage
import Foundation

class H264ContentViewModel {
    public let controlPanelViewModel = ControlPanelViewModel()

    public let textureStream = PassthroughSubject<MTLTexture, Never>()
    public let sampleBuffer: AnyPublisher<CMSampleBuffer, Never>
    private let sampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    private var client: Client?
    private var server: Server? {
        didSet {
            setupServer()
        }
    }

    private let factory = PixelBufferFactory(width: 128, height: 128)
    private let encoder = Encoder()
    private let decoder = Decoder()

    private var cancellables: Set<AnyCancellable> = []
    init() {
        sampleBuffer = sampleBufferSubject.eraseToAnyPublisher()

        controlPanelViewModel.config.sink { [weak self] (entity: ControlPanelEntity) in
            self?.server = entity.server ? Server() : nil
            self?.client = (entity.clientLocal || entity.clientRemote) ? Client(connectToRemote: entity.clientRemote) : nil
        }.store(in: &cancellables)

        setupCodec(textureStream: textureStream.eraseToAnyPublisher())

        // for debug
//        setupDirect(textureStream: textureStream.eraseToAnyPublisher())
    }

    private func setupCodec(textureStream: AnyPublisher<MTLTexture, Never>) {
        textureStream
            .receive(on: DispatchQueue(label: "hogehoge.fuga.hogegggggg.encode"))
            .sink { [weak self] (texture: MTLTexture) in
                guard let self = self else { return }
                let imageBuffer = self.factory
                    .make(size: .init(width: texture.width, height: texture.height)) { (context, buff) in
                        let ci = CIImage(mtlTexture: texture, options: nil)!
                        let ci2 = ci.transformed(by: .init(scaleX: 1, y: -1))
                            .transformed(by: .init(translationX: 0, y: CGFloat(texture.height)))
                        context.render(ci2, to: buff)
                }!
                let scale: UInt64 = 1_000_000_000
                self.encoder.encode(imageBuffer: imageBuffer,
                                    presentationTimeStamp: self.currentCmTime,
                                    duration: CMTime(value: CMTimeValue(scale / UInt64(30)), timescale: CMTimeScale(scale)))
            }
            .store(in: &cancellables)

        encoder
            .encodedSampleBuffer
            .map { EncodedFrameEntity.make(from: $0) }
            .receive(on: DispatchQueue(label: "hogehoge.fuga.hogegggggg.encoded"))
            .sink { [weak self] frameEntity in
                let b64 = EncodedFrameEntityBase64(nonBase64: frameEntity)
                let data = try! JSONEncoder().encode(b64)
                print("data count: \(data.count)")
                self?.client?.send(message: data)
            }
            .store(in: &cancellables)

        decoder
            .decodedFrameEntity
            .sink { [weak self] (entity: DecodedFrameEntity) in
                self?.sampleBufferSubject.send(entity.toSampleBuffer()!)
            }
            .store(in: &cancellables)
    }

    private func setupServer() {
        server?.onReceiveMessage
            .receive(on: DispatchQueue(label: "hogehoge.fuga.hogegggggg.decode"))
            .sink { [weak self] (data: Data) in
                print("onReceiveMessage data: \(data.count)")
                let e = try! JSONDecoder().decode(EncodedFrameEntityBase64.self, from: data)
                self?.decoder.decode(sampleBuffer: e.nonBase64.toSampleBuffer()!)
            }
            .store(in: &cancellables)
    }

    private func setupDirect(textureStream: AnyPublisher<MTLTexture, Never>) {
        textureStream
            .compactMap { [weak self] (texture: MTLTexture) -> CMSampleBuffer? in
                guard let self = self else { return nil }
                let cm = self.factory.make(size: .init(width: texture.width, height: texture.height),
                                           time: self.currentCmTime) { (context, buff) in
                    let ci = CIImage(mtlTexture: texture, options: nil)!
                    let ci2 = ci.transformed(by: .init(scaleX: 1, y: -1))
                        .transformed(by: .init(translationX: 0, y: CGFloat(texture.height)))
                    context.render(ci2, to: buff)
                }
                return cm
            }
            .sink { [weak self] (sampleBuffer: CMSampleBuffer) in
                self?.sampleBufferSubject.send(sampleBuffer)
            }
            .store(in: &cancellables)
    }

    private var currentCmTime: CMTime {
        var tb = mach_timebase_info()
        mach_timebase_info(&tb)
        let tsc = mach_absolute_time()
        let currentNanoSec = Double(tsc) * Double(tb.numer) / Double(tb.denom)
        return CMTime(value: CMTimeValue(currentNanoSec),
                      timescale: 1_000_000_000,
                      flags: .init(rawValue: 3),
                      epoch: 0)
    }
}
