import SwiftUI
import AVFoundation
import MediaPlayer
import Combine

class MusicPlayerViewModel: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var totalTime: Double = 0
    @Published var isPlaying: Bool = false
    @Published var currentSongIndex: Int = 0
    @Published var isSeeking: Bool = false
    @Published var errorMessage: String?
    @Published var showPopup: Bool = false
    @Published var isDeviceTurnedAround: Bool = false
    
    var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    let playlistManager: MusicPlaylistManager
    let motionManager: MotionManager
    var cancellables = Set<AnyCancellable>()
    
    init(playlistManager: MusicPlaylistManager) {
        self.playlistManager = playlistManager
        self.motionManager = MotionManager()
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        motionManager.$isTurnedAround
            .sink { [weak self] isTurnedAround in
                self?.isDeviceTurnedAround = isTurnedAround
                if isTurnedAround {
                    self?.playAudio()
                } else {
                    self?.pauseAudio()
                }
            }
            .store(in: &cancellables)
    }
    
    func handlePlayPause() {
        if isPlaying {
            pauseAudio()
        } else {
            showPopup = true
        }
    }
    
    func startStudy() {
        motionManager.startMotionUpdates()
    }
    
    func getCurrentSong() -> MusicItem? {
        guard !playlistManager.currentPlaylist.isEmpty else { return nil }
        return playlistManager.currentPlaylist[currentSongIndex]
    }
    
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func setupAudioPlayer() {
        guard let currentSong = getCurrentSong(), let assetURL = currentSong.assetURL else {
            errorMessage = "No song selected or asset URL not available"
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: assetURL)
            audioPlayer?.prepareToPlay()
            totalTime = audioPlayer?.duration ?? 0
            currentTime = 0
            startTimer()
            errorMessage = nil
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
            errorMessage = "Failed to load audio: \(error.localizedDescription)"
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.currentTime = self.audioPlayer?.currentTime ?? 0
        }
    }
    
    func seekAudio(to time: Double) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func playAudio() {
        if audioPlayer == nil {
            setupAudioPlayer()
        }
        
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func handleSkipForward() {
        seekAudio(to: min(currentTime + 15, totalTime))
    }
    
    func handleSkipBackward() {
        seekAudio(to: max(currentTime - 15, 0))
    }
    
    func handleNextSong() {
        guard !playlistManager.currentPlaylist.isEmpty else { return }
        currentSongIndex = (currentSongIndex + 1) % playlistManager.currentPlaylist.count
        setupAudioPlayer()
        if isPlaying {
            playAudio()
        }
    }
    
    func handlePreviousSong() {
        guard !playlistManager.currentPlaylist.isEmpty else { return }
        currentSongIndex = (currentSongIndex - 1 + playlistManager.currentPlaylist.count) % playlistManager.currentPlaylist.count
        setupAudioPlayer()
        if isPlaying {
            playAudio()
        }
    }
    
    func handleStopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        totalTime = 0
        timer?.invalidate()
        timer = nil
    }
}


struct MusicPlayerView: View {
    @StateObject private var playlistManager = MusicPlaylistManager()
    @StateObject private var viewModel: MusicPlayerViewModel
    @State private var showPlaylistPicker = false
    @State private var showPopup = false // Added @State variable
    
    init() {
        let manager = MusicPlaylistManager()
        _playlistManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: MusicPlayerViewModel(playlistManager: manager))
    }
    
    var body: some View {
        ZStack {
            Image("image4").resizable().ignoresSafeArea()
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.clear)
                .background(
                    TransparentBlurView(removeFilters: true)
                        .blur(radius: 25, opaque: true)
                        .background(Color.white.opacity(0.05))
                )
                .clipShape(.rect(cornerRadius: 25, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(.white.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 10)
                .ignoresSafeArea()
            VStack {
                
                if let currentSong = viewModel.getCurrentSong() {
                    CarouselCardView(currentSong: currentSong)
                        .transition(.move(edge: .leading))
                        .animation(.easeInOut, value: viewModel.currentSongIndex)
                        .padding([.top, .bottom])
                } else {
                    CarouselCardView(currentSong: nil)
                        .padding([.top, .bottom])
                }
                
                Slider(
                    value: $viewModel.currentTime,
                    in: 0...(viewModel.totalTime > 0 ? viewModel.totalTime : 1),
                    step: 1
                ) { editing in
                    viewModel.isSeeking = editing
                    if !editing {
                        viewModel.seekAudio(to: viewModel.currentTime)
                    }
                }
                .accentColor(.black.opacity(0.5))
                .padding(.horizontal)
                .disabled(viewModel.getCurrentSong() == nil || viewModel.totalTime <= 0)
                
                HStack {
                    Text(viewModel.formatTime(viewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                    
                    Spacer()
                    
                    Text(viewModel.formatTime(viewModel.totalTime))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding(.horizontal)
                
                HStack {
                    Button(action: viewModel.handleSkipBackward) {
                        Image(systemName: "15.arrow.trianglehead.counterclockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: viewModel.handlePreviousSong) {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: {
                        if viewModel.isPlaying {
                            viewModel.pauseAudio()
                        } else {
                            showPopup = true // Changed the action here
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.3))
                                .frame(width: 85, height: 85)
                            
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: viewModel.handleNextSong) {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Button(action: viewModel.handleSkipForward) {
                        Image(systemName: "15.arrow.trianglehead.clockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                }
                .padding(.top, 30)
                
                HStack {
                    Button(action: {}) {
                        Image(systemName: "bookmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "repeat")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    .disabled(viewModel.getCurrentSong() == nil)
                    
                    Spacer()
                    
                    Button(action: { showPlaylistPicker = true }) {
                        Image(systemName: "text.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 30)
            }
            .padding()
            
            if showPopup { // Changed to use the @State variable
                PopupView(showPopup: $showPopup, startStudy: {
                    viewModel.startStudy()
                    viewModel.playAudio()
                })
                .transition(.opacity)
                .zIndex(1) // Ensure the popup is on top
            }
        }
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerView(playlistManager: playlistManager) { selectedPlaylist in
                let wasPlaying = viewModel.isPlaying
                let currentPlaylistId = playlistManager.currentPlaylistId
                
                if currentPlaylistId != selectedPlaylist.persistentID {
                    viewModel.handleStopAudio()
                    playlistManager.loadPlaylist(selectedPlaylist)
                    viewModel.currentSongIndex = 0
                    viewModel.setupAudioPlayer()
                    if wasPlaying {
                        viewModel.audioPlayer?.play()
                        viewModel.isPlaying = true
                    }
                } else {
                    print("同じプレイリストが選択されました。再生を継続します。")
                }
            }
        }
        .onAppear {
            viewModel.setupAudioPlayer()
        }
        .onDisappear {
            viewModel.handleStopAudio()
        }
    }
}

