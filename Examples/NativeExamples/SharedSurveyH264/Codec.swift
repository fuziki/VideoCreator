//
//  Codec.swift
//  NativeExamples
//
//  Created by fuziki on 2021/12/26.
//

import CoreMedia
import CoreVideo
import Combine
import Foundation
import VideoToolbox

struct EncodedFrameEntity {
    let sps: [UInt8]
    let pps: [UInt8]
    let body: [Int8]
    let time: CMTime
}

class Encoder {
    private var session: VTCompressionSession?

    public let encodedSampleBuffer: AnyPublisher<CMSampleBuffer, Never>
    private let encodedSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    public let encodedFrameEntity: AnyPublisher<EncodedFrameEntity, Never>
    private let encodedFrameEntitySubject = PassthroughSubject<EncodedFrameEntity, Never>()

    private var cancellables: Set<AnyCancellable> = []
    public init() {
        encodedSampleBuffer = encodedSampleBufferSubject
            .share()
            .eraseToAnyPublisher()
        encodedFrameEntity = encodedFrameEntitySubject
            .share()
            .eraseToAnyPublisher()
        encodedSampleBuffer
            .compactMap { [weak self] sampleBuffer -> EncodedFrameEntity? in
                return self?.convert(sampleBuffer: sampleBuffer)
            }
            .share()
            .sink { [weak self] entity in
                self?.encodedFrameEntitySubject.send(entity)
            }
            .store(in: &cancellables)
    }

    private func setup(width: Int32, height: Int32) {
        var session: VTCompressionSession?
        let encoderSpecification: CFDictionary? = nil
        let imageBufferAttributes: CFDictionary? = nil
        let res = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                             width: width,
                                             height: height,
                                             codecType: kCMVideoCodecType_H264,
                                             encoderSpecification: encoderSpecification,
                                             imageBufferAttributes: imageBufferAttributes,
                                             compressedDataAllocator: nil,
                                             outputCallback: outputCallback,
                                             refcon: Unmanaged.passUnretained(self).toOpaque(),
                                             compressionSessionOut: &session)
        if res != noErr {
            print("failed create VTCompressionSession: \(res)")
            return
        }
        // set low quality
//        VTSessionSetProperty(session!, key: kVTCompressionPropertyKey_AverageBitRate, value: width * height as CFTypeRef)
        self.session = session
    }

    private let outputCallback: VTCompressionOutputCallback = { (outputCallbackRefCon: UnsafeMutableRawPointer?,
                                                                 sourceFrameRefCon: UnsafeMutableRawPointer?,
                                                                 status: OSStatus,
                                                                 infoFlags: VTEncodeInfoFlags,
                                                                 sampleBuffer: CMSampleBuffer?) in
        guard let outputCallbackRefCon = outputCallbackRefCon else { return }
        let refcon = Unmanaged<Encoder>.fromOpaque(outputCallbackRefCon).takeUnretainedValue()
        refcon.callback(outputCallbackRefCon: outputCallbackRefCon,
                        sourceFrameRefCon: sourceFrameRefCon,
                        status: status,
                        infoFlags: infoFlags,
                        sampleBuffer: sampleBuffer)
    }

    private func callback(outputCallbackRefCon: UnsafeMutableRawPointer?,
                          sourceFrameRefCon: UnsafeMutableRawPointer?,
                          status: OSStatus,
                          infoFlags: VTEncodeInfoFlags,
                          sampleBuffer: CMSampleBuffer?) {
        let infoFlags = infoFlags == .asynchronous ? ".asynchronous" : ".frameDropped"
        let size = (sampleBuffer?.dataBuffer?.dataLength).flatMap { Float($0) / 1_000 } ?? -1
        print("encoded infoFlags: \(infoFlags), size: \(size)KB")
        guard status == noErr else {
            print("encode error: \(status)")
            return
        }
        guard let sampleBuffer = sampleBuffer else {
            print("encode error: no sampleBuffer")
            return
        }
        encodedSampleBufferSubject.send(sampleBuffer)
    }
    
    var isFirst: Bool = true
    
    private func convert(sampleBuffer: CMSampleBuffer) -> EncodedFrameEntity? {
        if isFirst {
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
            print("original formatDescription: \(formatDescription)")
            isFirst = false
        }
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        let sps = getH264Parameter(formatDescription: formatDescription, index: 0)
        let pps = getH264Parameter(formatDescription: formatDescription, index: 1)
        let body = getData(sampleBuffer: sampleBuffer)
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        print("sps: \(sps?.count ?? -1), pps: \(pps?.count ?? -1), body: \(body?.count ?? -1)")
        return EncodedFrameEntity(sps: sps!, pps: pps!, body: body!, time: time)
    }
    
    private func getData(sampleBuffer: CMSampleBuffer) -> [Int8]? {
        let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)!
        let offset: Int = 0
        var offsetOut: Int = 0
        var lengthOut: Int = 0
        var ptrOut: UnsafeMutablePointer<Int8>? = nil
        let res = CMBlockBufferGetDataPointer(blockBuffer,
                                              atOffset: offset,
                                              lengthAtOffsetOut: &offsetOut,
                                              totalLengthOut: &lengthOut,
                                              dataPointerOut: &ptrOut)
        guard res == noErr, let ptr = ptrOut else {
            print("failed get data")
            return nil
        }
        let buffer = UnsafeBufferPointer(start: ptr, count: lengthOut)
        return Array(buffer)
    }
    
    private func getH264Parameter(formatDescription: CMFormatDescription, index: Int) -> [UInt8]? {
        var ptrOut: UnsafePointer<UInt8>?
        var size: Int = 0
        var count: Int = 0
        var nal: Int32 = 0
        let res = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription,
                                                                     parameterSetIndex: index,
                                                                     parameterSetPointerOut: &ptrOut,
                                                                     parameterSetSizeOut: &size,
                                                                     parameterSetCountOut: &count,
                                                                     nalUnitHeaderLengthOut: &nal)
        guard res == noErr, let ptr = ptrOut else {
            print("failed get h264 parameter: \(res)")
            return nil
        }
        print("h264 parameter index: \(index), size: \(size), count: \(count), nal: \((nal as Int32?) ?? -1)")
        let buffer = UnsafeBufferPointer(start: ptr, count: size)
        return Array(buffer)
    }

    public func encode(imageBuffer: CVImageBuffer, presentationTimeStamp: CMTime, duration: CMTime) {
        if session == nil {
            setup(width: Int32(CVPixelBufferGetWidth(imageBuffer)), height: Int32(CVPixelBufferGetHeight(imageBuffer)))
        }
        guard let session = session else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let mb = Float(bytesPerRow * height / 1_000) / 1_000
        print("encode frame size: \(mb)MB, w: \(width), h: \(height), bpp: \(bytesPerRow / width)")
        var infoFlagsOut: VTEncodeInfoFlags = []
        let res = VTCompressionSessionEncodeFrame(session,
                                                  imageBuffer: imageBuffer,
                                                  presentationTimeStamp: presentationTimeStamp,
                                                  duration: duration,
                                                  frameProperties: nil,
                                                  sourceFrameRefcon: nil,
                                                  infoFlagsOut: &infoFlagsOut)
        if res != noErr {
            print("faield encode frame: \(res)")
        }
    }
}

class Decoder {
    private var session: VTDecompressionSession?

    public let decodedSampleBuffer: AnyPublisher<CMSampleBuffer, Never>
    private let decodedSampleBufferSubject = PassthroughSubject<CMSampleBuffer, Never>()

    public init() {
        decodedSampleBuffer = decodedSampleBufferSubject.eraseToAnyPublisher()
    }

    private func setup(formatDescription: CMFormatDescription) {
        var session: VTDecompressionSession?
        let decoderSpecification: CFDictionary? = nil
        let imageBufferAttributes: CFDictionary? = nil
        var outputCallback = VTDecompressionOutputCallbackRecord(decompressionOutputCallback: decompressionOutputCallback,
                                                                 decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque())
        let res = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                               formatDescription: formatDescription,
                                               decoderSpecification: decoderSpecification,
                                               imageBufferAttributes: imageBufferAttributes,
                                               outputCallback: &outputCallback,
                                               decompressionSessionOut: &session)
        if res != noErr {
            print("failed create VTDecompressionSession")
            return
        }
        self.session = session
    }

    private var decompressionOutputCallback: VTDecompressionOutputCallback = { (decompressionOutputRefCon: UnsafeMutableRawPointer?,
                                                                                sourceFrameRefCon: UnsafeMutableRawPointer?,
                                                                                status: OSStatus,
                                                                                infoFlags: VTDecodeInfoFlags,
                                                                                imageBuffer: CVImageBuffer?,
                                                                                presentationTimeStamp: CMTime,
                                                                                presentationDuration: CMTime) in
        guard let decompressionOutputRefCon = decompressionOutputRefCon else { return }
        let refcon = Unmanaged<Decoder>.fromOpaque(decompressionOutputRefCon).takeUnretainedValue()
        refcon.callback(decompressionOutputRefCon: decompressionOutputRefCon,
                        sourceFrameRefCon: sourceFrameRefCon,
                        status: status,
                        infoFlags: infoFlags,
                        imageBuffer: imageBuffer,
                        presentationTimeStamp: presentationTimeStamp,
                        presentationDuration: presentationDuration)
    }

    private func callback(decompressionOutputRefCon: UnsafeMutableRawPointer?,
                          sourceFrameRefCon: UnsafeMutableRawPointer?,
                          status: OSStatus,
                          infoFlags: VTDecodeInfoFlags,
                          imageBuffer: CVImageBuffer?,
                          presentationTimeStamp: CMTime,
                          presentationDuration: CMTime) {
        guard let imageBuffer = imageBuffer else {
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            print("no decoded imageBuffer: \(error.localizedDescription)")
            return
        }

        var formatDescriptionOut: CMVideoFormatDescription?
        let res1 = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                imageBuffer: imageBuffer,
                                                                formatDescriptionOut: &formatDescriptionOut
        )
        guard let formatDescription = formatDescriptionOut,
              res1 == noErr else {
                  print("failed to create formatDescription: \(res1)")
                  return
              }

        var sampleTiming = CMSampleTimingInfo(duration: presentationDuration,
                                              presentationTimeStamp: presentationTimeStamp,
                                              decodeTimeStamp: .invalid)

        var sampleBuffer: CMSampleBuffer?
        let res2 = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                      imageBuffer: imageBuffer,
                                                      dataReady: true,
                                                      makeDataReadyCallback: nil,
                                                      refcon: nil,
                                                      formatDescription: formatDescription,
                                                      sampleTiming: &sampleTiming,
                                                      sampleBufferOut: &sampleBuffer)
        guard let res = sampleBuffer,
              res2 == noErr else {
                  print("failed to create CMSampleBuffer: \(res2)")
                  return
              }
        print("decoded frame")
        decodedSampleBufferSubject.send(res)
    }

    public func decode(sampleBuffer: CMSampleBuffer) {
        if session == nil {
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
            print("formatDescription: \(formatDescription)")
            setup(formatDescription: formatDescription)
        }
        guard let session = session else { return }
        print("decode frame")
        let flags: VTDecodeFrameFlags = []
        var infoFlagsOut: VTDecodeInfoFlags = []
        let res = VTDecompressionSessionDecodeFrame(session,
                                                    sampleBuffer: sampleBuffer,
                                                    flags: flags,
                                                    frameRefcon: nil,
                                                    infoFlagsOut: &infoFlagsOut)
        if res != noErr {
            print("faield decode frame: \(res)")
        }
    }
    
    public func decode(frameEntity: EncodedFrameEntity) {
        var sampleBufferOut: CMSampleBuffer?
        let blockBuffer = makeMemoryBlock(frameEntity: frameEntity)!
        let formatDescription = makeFormatDescription(frameEntity: frameEntity)
        var sampleSizeArray: [Int] = [frameEntity.body.count]
        
        var timingInfo = CMSampleTimingInfo()
        timingInfo.decodeTimeStamp = .invalid
        timingInfo.presentationTimeStamp = frameEntity.time
        timingInfo.duration = .invalid// CMTime(value: 16_000, timescale: 1_000_000)
        
        let res = CMSampleBufferCreate(allocator: kCFAllocatorDefault,
                                       dataBuffer: blockBuffer,
                                       dataReady: true,
                                       makeDataReadyCallback: nil,
                                       refcon: nil,
                                       formatDescription: formatDescription,
                                       sampleCount: 1,
                                       sampleTimingEntryCount: 1,
                                       sampleTimingArray: &timingInfo,
                                       sampleSizeEntryCount: 1,
                                       sampleSizeArray: &sampleSizeArray,
                                       sampleBufferOut: &sampleBufferOut)
        guard res == noErr, let sampleBuffer = sampleBufferOut else {
            print("failed create sampleBuffer: \(res)")
            return
        }
        self.decode(sampleBuffer: sampleBuffer)
    }
    
    private func makeMemoryBlock(frameEntity: EncodedFrameEntity) -> CMBlockBuffer? {
        var blockBufferOut: CMBlockBuffer?
        let res = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                     memoryBlock: nil,
                                                     blockLength: frameEntity.body.count,
                                                     blockAllocator: nil,
                                                     customBlockSource: nil,
                                                     offsetToData: 0,
                                                     dataLength: frameEntity.body.count,
                                                     flags: 0,
                                                     blockBufferOut: &blockBufferOut)
        guard res == noErr, let blockBuffer = blockBufferOut else {
            print("failed crete blockBuffer: \(res)")
            return nil
        }
        frameEntity.body.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            _ = CMBlockBufferReplaceDataBytes(with: ptr.baseAddress!,
                                              blockBuffer: blockBuffer,
                                              offsetIntoDestination: 0,
                                              dataLength: frameEntity.body.count)
        }
        return blockBuffer
    }
    
    private func makeFormatDescription(frameEntity: EncodedFrameEntity) -> CMFormatDescription? {
        var formatDescriptionOut: CMVideoFormatDescription? = nil
        let parameters: [[UInt8]] = [
            frameEntity.sps,
            frameEntity.pps
        ]
        var parameterSetPointers: [UnsafePointer<UInt8>] = parameters.map { (arr: [UInt8]) in
            let res = UnsafeMutablePointer<UInt8>.allocate(capacity: arr.count)
            arr.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
                _ = memcpy(res, src.baseAddress!, arr.count)
            }
            return UnsafePointer<UInt8>(res)
        }
        let parameterSetSizes: [Int] = parameters.map { $0.count }
        let res = CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                                                                      parameterSetCount: parameters.count,
                                                                      parameterSetPointers: &parameterSetPointers,
                                                                      parameterSetSizes: parameterSetSizes,
                                                                      nalUnitHeaderLength: 4,
                                                                      formatDescriptionOut: &formatDescriptionOut)
        guard res == noErr, let formatDescription = formatDescriptionOut else {
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(res), userInfo: nil)
            print("failed create formatDescription: \(error.localizedDescription)")
            return nil
        }
        return formatDescription
    }
}
