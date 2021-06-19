//
//  WavExampleApp.swift
//  WavExample
//
//  Created by fuziki on 2021/06/19.
//

import SwiftUI

@main
struct WavExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct AppConfig {
    static let fs: Double = 44_100
}
