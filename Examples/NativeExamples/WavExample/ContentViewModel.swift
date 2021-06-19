//
//  ContentViewModel.swift
//  WavExample
//
//  Created by fuziki on 2021/06/19.
//

import Foundation
import SwiftUI
import UnityVideoCreator

class ContentViewModel: ObservableObject {
    public var label: String {
        return recording ? "recording" : "prepare"
    }
    
    @Published private var recording: Bool = false
    
    init() {
        
    }
    
    public func tapButton() {
        recording.toggle()
        if recording {
            UnityMediaCreator_initAsMovWithNoAudio(<#T##url: UnsafePointer<CChar>?##UnsafePointer<CChar>?#>, <#T##codec: UnsafePointer<CChar>?##UnsafePointer<CChar>?#>, <#T##width: Int64##Int64#>, <#T##height: Int64##Int64#>)
            
        } else {
            
            
        }
        
    }
}
