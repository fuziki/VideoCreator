//
//  EncodedFrameEntity.swift
//  NativeExamples
//
//  Created by fuziki on 2022/01/01.
//

import Foundation
import CoreMedia

struct EncodedFrameEntity {
    let sps: [UInt8]
    let pps: [UInt8]
    let body: [UInt8]
    let microSec: Int
}

struct EncodedFrameEntityBase64: Codable {
    let sps: String
    let pps: String
    let body: String
    let microSec: Int
    init(nonBase64: EncodedFrameEntity) {
        sps = Data(nonBase64.sps).base64EncodedString()
        pps = Data(nonBase64.pps).base64EncodedString()
        body = Data(nonBase64.body).base64EncodedString()
        microSec = nonBase64.microSec
    }
    var nonBase64: EncodedFrameEntity {
        return .init(sps: [UInt8](Data(base64Encoded: sps)!),
                     pps: [UInt8](Data(base64Encoded: pps)!),
                     body: [UInt8](Data(base64Encoded: body)!),
                     microSec: microSec)
    }
}

extension EncodedFrameEntity {
    public static func make(from sampleBuffer: CMSampleBuffer) -> EncodedFrameEntity {
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        let sps = getH264Parameter(formatDescription: formatDescription, index: 0)
        let pps = getH264Parameter(formatDescription: formatDescription, index: 1)
        let body = getData(sampleBuffer: sampleBuffer)
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        print("sps: \(sps?.count ?? -1), pps: \(pps?.count ?? -1), body: \(body?.count ?? -1)")
        let microSec: Int = Int(time.seconds * 1_000_000)
        return EncodedFrameEntity(sps: sps!, pps: pps!, body: body!, microSec: microSec)
    }

    private static func getData(sampleBuffer: CMSampleBuffer) -> [UInt8]? {
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
        var buff = [UInt8](repeating: 0, count: lengthOut)
        buff.withUnsafeMutableBytes { (dst: UnsafeMutableRawBufferPointer) in
            _ = memcpy(dst.baseAddress, ptr, lengthOut)
        }
        return buff
    }

    private static func getH264Parameter(formatDescription: CMFormatDescription, index: Int) -> [UInt8]? {
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
}

extension EncodedFrameEntity {
    public func toSampleBuffer() -> CMSampleBuffer? {
        var sampleBufferOut: CMSampleBuffer?
        let blockBuffer = makeBlockBuffer(frameEntity: self)!
        let formatDescription = makeFormatDescription(frameEntity: self)
        var sampleSizeArray: [Int] = [self.body.count]

        var timingInfo = CMSampleTimingInfo()
        timingInfo.decodeTimeStamp = .invalid
        timingInfo.presentationTimeStamp = CMTime(value: CMTimeValue(self.microSec), timescale: 1_000_000)
        let scale: UInt64 = 1_000_000
        timingInfo.duration = CMTime(value: CMTimeValue(scale / UInt64(30)), timescale: CMTimeScale(scale))

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
            return nil
        }
        return sampleBuffer
    }

    private func makeBlockBuffer(frameEntity: EncodedFrameEntity) -> CMBlockBuffer? {
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
