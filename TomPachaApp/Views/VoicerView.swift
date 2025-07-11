import SwiftUI
import Combine
import AVFoundation
import Speech


struct VoicerView: View {
    @State private var voiceLevel: CGFloat = 0
    @State private var isSpeaking = false
    @State private var isPlaying = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioFileHandle: AudioFileHandle?
    @State private var timer: Timer?
    @State private var audioFileURL: URL?
    
    @State private var transcript: String = ""
    @State private var transcriptResponse: String = ""
    let minLevel: CGFloat = 0.1
    let maxLevel: CGFloat = 1.0
    
    let synthesizer = AVSpeechSynthesizer()
    
    init() {}
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated circle that responds to voice level
            Circle()
                .fill(isPlaying ? Color.green : Color.blue)
                .frame(width: 200, height: 200)
                .scaleEffect(1 + voiceLevel * 0.5)
                .opacity(0.5 + voiceLevel * 0.5)
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: voiceLevel)
            
            VStack {
                Text(isSpeaking ? "Recording..." : "Ready")
                //Text(isPlaying ? "Playing back..." : "")
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    transcript = ""
                    transcriptResponse = ""
                    if isSpeaking {
                        stopRecording()
                        transcribe()
                    } else {
                        startRecording()
                    }
                }) {
                    Text(isSpeaking ? "Stop Recording" : "Start Recording")
                        .padding()
                        .background(isSpeaking ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            ScrollView {
                Text(transcript)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(transcriptResponse)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onDisappear {
            stopRecording()
            stopPlayback()
        }
        .onReceive(audioFileHandle?.$isPlaying.eraseToAnyPublisher() ?? Just(false).eraseToAnyPublisher(), perform: { newLevel in
            isPlaying = newLevel
        })
    }
    
    func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    setupAudioRecorder()
                    startVoiceLevelTimer()
                    isSpeaking = true
                    isPlaying = false
                }
            } else {
                print("Microphone permission denied")
            }
        }
    }
    
    func stopRecording() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isSpeaking = false
        voiceLevel = 0
    }
    
    func startPlayback() {
        guard let url = audioFileURL else { return }
        
        audioFileHandle  = AudioFileHandle(url: url)
        audioFileHandle?.isPlaying = true
        
        isPlaying = true
        startPlaybackLevelTimer()
        
    }
    
    func stopPlayback() {
        
        audioFileHandle?.isPlaying = false
        audioFileHandle = nil
        voiceLevel = 0
    }
    
    
    private func setupAudioRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFileURL = documentsPath.appendingPathComponent("recording.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFileURL!, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            print("Failed to setup audio recorder: \(error.localizedDescription)")
        }
    }
    
    private func startVoiceLevelTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateVoiceLevel(fromRecorder: true)
        }
    }
    
    private func startPlaybackLevelTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateVoiceLevel(fromRecorder: false)
        }
    }
    
    private func updateVoiceLevel(fromRecorder: Bool) {
        let linearLevel: Float
        
        if fromRecorder {
            audioRecorder?.updateMeters()
            let power = audioRecorder?.averagePower(forChannel: 0) ?? -80
            linearLevel = pow(10, power / 20)
        } else {
            audioFileHandle?.audioPlayer.updateMeters()
            let power = audioFileHandle?.audioPlayer.averagePower(forChannel: 0) ?? -80
            linearLevel = pow(10, power / 20)
        }
        
        // Apply some smoothing and scaling
        let adjustedLevel = max(Float(minLevel), min(Float(maxLevel), linearLevel * 2))
        
        // If level is very low, consider it silence
        if adjustedLevel < Float(minLevel * 1.1) {
            voiceLevel = 0
        } else {
            voiceLevel = CGFloat(adjustedLevel)
        }
    }
    
    
    func transcribe() {
        
        guard let audioFileURL = audioFileURL else {
            print("No audio file URL available yet.")
            return
        }
    
      SFSpeechRecognizer.requestAuthorization {
          authStatus in
          DispatchQueue.main.async {
              if authStatus == .authorized {
                  transcribeFile(url: audioFileURL)
              }
          }
       }
    }
    
    func transcribeFile(url:URL) {
        
        guard let myRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US")) else {
            return
        }
        
        if !myRecognizer.isAvailable {
            print("The recognizer is not available right now")
            return
        }
        
        let path_to_audio = url
        
        let request = SFSpeechURLRecognitionRequest(url: path_to_audio)
        
        myRecognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                return
            }
            if result.isFinal {
                print(result.bestTranscription.formattedString)
                transcript = result.bestTranscription.formattedString
                
                Task {
                    var response = await FoundationModelHelper.getFoundationModel(prompt: transcript)
                    if response.isEmpty {
                        response = "Sorry, I couldn't generate a response."
                    }
                   
                    DispatchQueue.main.async {
                        transcriptResponse = response
                        speak(text: response)
                    }
                    
                }
            }
        }
    }
    
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}


class AudioFileHandle: NSObject, ObservableObject, AVAudioPlayerDelegate {
    
    @Published var isPlaying: Bool = false {
        willSet {
            if newValue {
                playAudio()
            }
        }
    }
    
    @Published
    var audioPlayer = AVAudioPlayer()
    
    @Published var audioFileURL: URL?
    
    var callback : (() -> Void)?
    
    
    init(url: URL?) {
        self.audioFileURL = url
    }
    
    func playAudio() {
        guard let url = audioFileURL else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            try audioPlayer = AVAudioPlayer(contentsOf: url)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
        
    }
    
    func stopAudio() {
        isPlaying = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        audioFileURL = nil
        if let callback = callback {
            callback()
        }
    }
}
    
    
