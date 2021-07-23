//
//  UnityMediaCreatorTest.swift
//  
//
//  Created by fuziki on 2021/06/19.
//

import AVFoundation
import XCTest
@testable import UnityVideoCreator

final class UnityMediaCreatorTest: XCTestCase {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("hoge", isDirectory: false)
    
    func testWritePcmInitAsMovWithAudio() {
        let mediaCreator = MediaCreatorMock()
        let provider = MediaCreatorProviderMock()
        provider.makeHandler = { _ in
            return mediaCreator
        }
        
        let testCreator = UnityMediaCreator(provider: provider)
        
        testCreator.initAsMovWithAudio(url: url.absoluteString, codec: "h264", width: 1920, height: 1080,
                                       channel: 1, samplingRate: 48_000,
                                       contentIdentifier: "")
        
        let pcm = [Float](repeating: 0, count: 1024)
        testCreator.write(pcm: pcm, frame: pcm.count, microSec: 0)
        
        XCTAssertEqual(mediaCreator.writePcmCallCount, 1)        
    }
    
    func testWritePcmInitAsMovWithNoAudio() {
        let mediaCreator = MediaCreatorMock()
        let provider = MediaCreatorProviderMock()
        provider.makeHandler = { _ in
            return mediaCreator
        }
        
        let testCreator = UnityMediaCreator(provider: provider)
        
        testCreator.initAsMovWithNoAudio(url: url.absoluteString, codec: "h264", width: 1920, height: 1080, contentIdentifier: "")
        
        let pcm = [Float](repeating: 0, count: 1024)
        testCreator.write(pcm: pcm, frame: pcm.count, microSec: 0)
        
        XCTAssertEqual(mediaCreator.writePcmCallCount, 0)
    }
    
    func testWritePcmInitAsWav() {
        let mediaCreator = MediaCreatorMock()
        let provider = MediaCreatorProviderMock()
        provider.makeHandler = { _ in
            return mediaCreator
        }
        
        let testCreator = UnityMediaCreator(provider: provider)
        
        testCreator.initAsWav(url: url.absoluteString, channel: 1, samplingRate: 48_000, bitDepth: 16)
        
        let pcm = [Float](repeating: 0, count: 1024)
        testCreator.write(pcm: pcm, frame: pcm.count, microSec: 0)
        
        XCTAssertEqual(mediaCreator.writePcmCallCount, 1)
    }
    
    enum FinishAction {
        case callFinish
        case finishSaved
        case endFinishSync
    }
    
    func testDeinit() {
        
        var deinitCallCount = 0
        var finishActions: [FinishAction] = []
        
        let provider = MediaCreatorProviderMock()
        provider.makeHandler = { _ in
            let mediaCreator = MediaCreatorMock()
            mediaCreator.deinitHandler = {
                deinitCallCount += 1
            }
            mediaCreator.finishHandler = { handler in
                finishActions.append(.callFinish)
                DispatchQueue(label: "factory.fuziki.unityVideoCreator.test").async {
                    finishActions.append(.finishSaved)
                    handler()
                }
            }
            return mediaCreator
        }
        
        let testCreator = UnityMediaCreator(provider: provider)
        
        testCreator.initAsMovWithAudio(url: url.absoluteString, codec: "h264", width: 1920, height: 1080,
                                       channel: 1, samplingRate: 48_000,
                                       contentIdentifier: "")

        XCTAssertEqual(deinitCallCount, 0)

        testCreator.finishSync()
        finishActions.append(.endFinishSync)
        
        XCTAssertEqual(deinitCallCount, 1)
        XCTAssertEqual(finishActions, [.callFinish, .finishSaved, .endFinishSync])
    }
}

