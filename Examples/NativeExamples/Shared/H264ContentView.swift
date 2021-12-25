//
//  ContentView.swift
//  Shared
//
//  Created by fuziki on 2021/12/24.
//

import SharedGameView
import SwiftUI

struct H264ContentView: View {
    var body: some View {
        SharedGameWrapperView()
            .didRender{ (texture: MTLTexture) in
                print("rendered: \(texture.width)")
            }
            .padding()
    }
}

struct H264ContentView_Previews: PreviewProvider {
    static var previews: some View {
        H264ContentView()
    }
}
