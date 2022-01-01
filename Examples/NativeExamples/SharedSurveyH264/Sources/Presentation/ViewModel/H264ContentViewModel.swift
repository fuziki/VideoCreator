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
import Metal
import Network

class H264ContentViewModel {
    public let textureStream = PassthroughSubject<MTLTexture, Never>()
    public let sampleBuffer: AnyPublisher<CMSampleBuffer, Never>
    private let sampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    private var client = Client()

    private let factory = SampleBufferVideoFactory(width: 128, height: 128)
    private let encoder = Encoder()
    private let decoder = Decoder()

    private var cancellables: Set<AnyCancellable> = []
    init() {
        sampleBuffer = sampleBufferSubject.eraseToAnyPublisher()

        setupCodec(textureStream: textureStream.eraseToAnyPublisher())
//        setupDirect(textureStream: textureStream.eraseToAnyPublisher())
    }

    private func setupCodec(textureStream: AnyPublisher<MTLTexture, Never>) {
        textureStream
            .sink { [weak self] (texture: MTLTexture) in
                guard let self = self else { return }
                let imageBuffer = self.factory
                    .make(size: .init(width: texture.width, height: texture.height)) { (context, buff) in
                        let ci = CIImage(mtlTexture: texture, options: nil)!
                        let ci2 = ci.transformed(by: .init(scaleX: 1, y: -1))
                            .transformed(by: .init(translationX: 0, y: CGFloat(texture.height)))
                        context.render(ci2, to: buff)
                }!
                self.encoder.encode(imageBuffer: imageBuffer,
                                    presentationTimeStamp: self.currentCmTime,
                                    duration: CMTime(value: 33_000_000, timescale: 1_000_000_000))
            }
            .store(in: &cancellables)

        encoder
            .encodedSampleBuffer
            .map { EncodedFrameEntity.make(from: $0) }
            .sink { [weak self] frameEntity in
                DispatchQueue(label: "hogehoge.encodable").async {
                    let b64 = EncodedFrameEntityBase64(nonBase64: frameEntity)
                    let data = try! JSONEncoder().encode(b64)
                    let e = try! JSONDecoder().decode(EncodedFrameEntityBase64.self, from: data)
                    DispatchQueue.main.async {
                        print("data count: \(data.count / 1000) KB")
                        self?.client.send(message: data)
                    }
                    DispatchQueue.main.async {
                        self?.decoder.decode(sampleBuffer: e.nonBase64.toSampleBuffer()!)
                    }
                }
            }
            .store(in: &cancellables)

        decoder
            .decodedSampleBuffer
            .sink { [weak self] (sampleBuffer: CMSampleBuffer) in
                self?.sampleBufferSubject.send(sampleBuffer)
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

class Client {
    var connection: NWConnection?

    init() {
        connection = NWConnection(host: .init("localhost"), port: .init(rawValue: 8080)!, using: .tcp)
//        connection = NWConnection(host: .init("192.168.3.33"), port: .init(rawValue: 8080)!, using: .tcp)
        connection?.stateUpdateHandler = { (state: NWConnection.State) in
            print("client state: \(state)")
        }
        connection?.start(queue: DispatchQueue.main)
    }

    public func send(message: Data) {
        if connection?.state != .ready {
            print("connection not ready: \(String(describing: connection?.state))")
            return
        }
        connection!.send(content: message,
                         completion: .contentProcessed({ e in print("e: \(String(describing: e))") }))
    }
}

class Server {
    public let onReceiveMessage: AnyPublisher<Data, Never>
    private let onReceiveMessageSubject = PassthroughSubject<Data, Never>()
    
    var listener: NWListener!
    
    var connections: [NWConnection] = []
    init() {
        onReceiveMessage = onReceiveMessageSubject.eraseToAnyPublisher()
        do {
            listener = try NWListener(using: .tcp, on: .init(rawValue: 8080)!)
        } catch let error {
            print("error: \(error)")
        }
        listener.newConnectionHandler = { [weak self] (connection: NWConnection) in
            self?.connections.append(connection)
            print("new connection: \(connection)")
            self?.sub(connection: connection)
            connection.start(queue: DispatchQueue.main)
        }

        listener.start(queue: DispatchQueue.main)
    }
        
    private func sub(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 0, maximumLength: .max) { [weak self] (completeContent: Data?,
                                                                                           contentContext: NWConnection.ContentContext?,
                                                                                           isComplete: Bool,
                                                                                           error: NWError?) in
            if let content = completeContent {
                self?.onReceiveMessageSubject.send(content)
            }
            if let error = error {
                print("error: \(error)")
            } else {
                self?.sub(connection: connection)
            }
        }
    }
}
