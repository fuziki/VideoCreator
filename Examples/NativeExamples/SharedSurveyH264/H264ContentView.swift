//
//  ContentView.swift
//  Shared
//
//  Created by fuziki on 2021/12/24.
//

import Combine
import SharedGameView
import SwiftUI

struct H264ContentView: View {
    let textureStream = PassthroughSubject<MTLTexture, Never>()
    var body: some View {
        VStack {
            SharedGameWrapperView()
                .didRender{ (texture: MTLTexture) in
                    print("rendered: \(texture.width)")
                    textureStream.send(texture)
                }
            SampleBufferDisplayViewRepresentable(textureStream: textureStream.eraseToAnyPublisher())
        }
        .padding()
    }
}

struct H264ContentView_Previews: PreviewProvider {
    static var previews: some View {
        H264ContentView()
    }
}
