//
//  ContentView.swift
//  Shared
//
//  Created by fuziki on 2021/12/24.
//

import SharedGameView
import SwiftUI

struct H264ContentView: View {
    let viewModel = H264ContentViewModel()
    var body: some View {
        VStack {
            SharedGameWrapperView()
                .didRender{ (texture: MTLTexture) in
                    print("rendered: \(texture.width)")
                    viewModel.textureStream.send(texture)
                }
                .frame(width: 640, height: 360)
            HStack {
                Image(systemName: "arrow.down")
                Text("H264 encode, decode")
            }
            .font(.system(size: 24))
            SampleBufferDisplayViewRepresentable(sampleBufferStream: viewModel.sampleBuffer)
        }
        .padding()
    }
}

struct H264ContentView_Previews: PreviewProvider {
    static var previews: some View {
        H264ContentView()
    }
}
