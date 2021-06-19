//
//  ContentView.swift
//  WavExample
//
//  Created by fuziki on 2021/06/19.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = ContentViewModel()
    var body: some View {
        VStack {
            Text("Hello, world!")
                .padding()
            Text(viewModel.label)
            Button(action: {
                viewModel.tapButton()
            }, label: {
                Text("Button")
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
