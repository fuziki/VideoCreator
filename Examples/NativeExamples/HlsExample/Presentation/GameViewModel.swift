//
//  GameViewModel.swift
//  HlsExample
//
//  Created by fuziki on 2021/08/09.
//

import Foundation
import Metal

protocol GameViewModelType {
    func setup(width: Int, height: Int)
    func onRender(texture: MTLTexture)
}

class GameViewModel: GameViewModelType {
    private let segmentDurationMicroSec: Int = 1_000_000
    
    private let serverService: HlsServerService
    private let hlsCreatorService: HlsCreatorService
    
    private var shouldSend: Bool = true

    init(serverService: HlsServerService = DefaultHlsServerService(),
         hlsCreatorService: HlsCreatorService = DefaultHlsCreatorService.shared) {
        self.serverService = serverService
        self.hlsCreatorService = hlsCreatorService

        self.serverService.segmentDurationMicroSec = segmentDurationMicroSec
        self.hlsCreatorService.onSegmentData = { [weak self] (data: Data) in
            self?.serverService.onSegmentData(data: data)
        }
    }
    
    public func setup(width: Int, height: Int) {
        hlsCreatorService.setup(width: width, height: height, segmentDurationMicroSec: segmentDurationMicroSec)
    }
    
    public func onRender(texture: MTLTexture) {
        self.shouldSend.toggle()
        if !self.shouldSend { return }
        hlsCreatorService.write(texture: texture)
    }
}
