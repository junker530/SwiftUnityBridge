import Foundation
import CoreMotion
import AVFoundation
import MediaPlayer

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private var musicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    @Published var isTurnedAround = false
    @Published var isStudyCompleted = false
    @Published var warningCleared = false
    
    private var vibrationTimer: Timer?
    
    init() {
        startMotionUpdates()
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                guard let motion = motion else { return }
                DispatchQueue.main.async {
                    let newValue = (abs(motion.attitude.roll) >= 2.9 && abs(motion.attitude.roll) <= 3.2)
                    if self.isTurnedAround != newValue {
                        self.isTurnedAround = newValue
                        if !self.isStudyCompleted {
                            if newValue {
                                self.stopContinuousVibration()
                            } else if !self.warningCleared {
                                self.startContinuousVibration()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func vibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func startContinuousVibration() {
        stopContinuousVibration() // Ensure any existing timer is invalidated
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.vibrate()
        }
    }
    
    func stopContinuousVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
    
    func resetStudyState() {
        isStudyCompleted = false
        resetWarningState()
    }
    
    func resetWarningState() {
        warningCleared = false
        stopContinuousVibration()
    }
}
