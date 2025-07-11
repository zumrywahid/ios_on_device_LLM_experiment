//
//  ContentView.swift
//  TomPachaApp
//
//  Created by Zumry on 26/06/2025.
//

import SwiftUI
import AVFoundation
import FoundationModels
import Combine

struct ContentView: View {
    
    @State var isTouching: Bool = false
    
    var body: some View {
        
        VStack {
            Spacer()
            VoicerView()
            Spacer()
        }
        
    }
    
}


struct AnimatedVoiceView: View {
    
    @State var isTouching: Bool = false
    
    @State var voiceLevel: CGFloat = 0
    
    @State var isRecording: Bool = false
    
    @State var isPlaying: Bool = false
    
    @State var isPaused: Bool = false
    
    @State var isFinished: Bool = false
    
    @State var isError: Bool = false
    
    @State var audioURL: URL?
    
    func toggleRecording() {
        
    }
    
    var body: some View {
        
        VStack {
            
            ZStack {
                
                Circle()
                    .stroke(Color.gray, lineWidth: 4)
                    .padding(.all, 100)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: voiceLevel * 100, height: voiceLevel * 100)
                
            }
            
        }
        
    }
    
}



#Preview {
    ContentView()
}
