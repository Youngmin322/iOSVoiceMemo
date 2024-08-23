import Foundation
import SwiftUI

class TimerViewModel: ObservableObject {
    @Published var isDisplaySetTimeView: Bool
    @Published var time: Time
    @Published var timer: Timer?
    @Published var timeRemaining: Int
    @Published var isPaused: Bool
    @Published var progress: CGFloat = 1.0 // 타이머 진행 상태를 나타내는 변수 추가
    var notificationService: NotificationService
    
    init(
        isDisplaySetTimeView: Bool = true,
        time: Time = .init(hours: 0, minutes: 0, seconds: 0),
        timer: Timer? = nil,
        timeRemaining: Int = 0,
        isPaused: Bool = true, // 기본적으로 일시정지 상태로 설정
        notificationService: NotificationService = .init()
    ) {
        self.isDisplaySetTimeView = isDisplaySetTimeView
        self.time = time
        self.timer = timer
        self.timeRemaining = timeRemaining
        self.isPaused = isPaused
        self.notificationService = notificationService
        self.loadState()
    }
    
    func saveState() {
        UserDefaults.standard.set(isDisplaySetTimeView, forKey: "isDisplaySetTimeView")
        UserDefaults.standard.set(timeRemaining, forKey: "timeRemaining")
        UserDefaults.standard.set(isPaused, forKey: "isPaused")
        UserDefaults.standard.set(progress, forKey: "progress")
    }
    
    func loadState() {
        if let savedTimeRemaining = UserDefaults.standard.value(forKey: "timeRemaining") as? Int,
           let savedIsPaused = UserDefaults.standard.value(forKey: "isPaused") as? Bool,
           let savedProgress = UserDefaults.standard.value(forKey: "progress") as? CGFloat {
            timeRemaining = savedTimeRemaining
            isPaused = savedIsPaused
            progress = savedProgress
            isDisplaySetTimeView = false // 앱이 복원되었으므로 설정 뷰는 숨김
            if !isPaused {
                startTimer() // 타이머가 실행 중이면 복원
            } else {
                stopTimer() // 일시정지 상태로 유지
            }
        } else {
            // 앱을 처음 시작할 때 설정 뷰를 표시
            isDisplaySetTimeView = true
        }
    }
    
    func clearState() {
        UserDefaults.standard.removeObject(forKey: "isDisplaySetTimeView")
        UserDefaults.standard.removeObject(forKey: "timeRemaining")
        UserDefaults.standard.removeObject(forKey: "isPaused")
        UserDefaults.standard.removeObject(forKey: "progress")
    }
    
    func resetTimer() {
        stopTimer() // 타이머를 중지
        
        // 기본 설정된 시간으로 초기화
        time = Time(hours: 0, minutes: 0, seconds: 0)
        timeRemaining = time.convertedSeconds
        progress = 1.0 // 진행 상태 초기화
        isPaused = true // 초기 상태를 일시정지 상태로 설정
        
        // 상태 저장
        saveState()
    }
    
    func settingBtnTapped() {
        // 타이머를 설정하고, 일시정지 상태로 유지
        isDisplaySetTimeView = false
        timeRemaining = time.convertedSeconds
        progress = 1.0 // 타이머 설정 시, 진행 상태를 1.0으로 설정
        isPaused = true // 타이머를 설정할 때 자동으로 일시정지 상태로 설정
        saveState() // 상태 저장
    }
    
    func cancelBtnTapped() {
        resetTimer() // 타이머를 초기화
        isDisplaySetTimeView = true
        clearState() // 상태 초기화
    }
    
    func pauseOrRestartBtnTapped() {
        if isPaused {
            startTimer()
        } else {
            stopTimer()
        }
        isPaused.toggle()
        saveState() // 상태 저장
    }
}

// MARK: - 타이머 제어 관련 메서드
private extension TimerViewModel {
    func startTimer() {
        guard timer == nil else { return }
        
        var backgroundTaskID: UIBackgroundTaskIdentifier?
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            if let task = backgroundTaskID {
                UIApplication.shared.endBackgroundTask(task)
                backgroundTaskID = .invalid
            }
        }
        
        timer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                self.updateProgress() // 타이머 진행 상태 업데이트
            } else {
                self.stopTimer()
                self.notificationService.sendNotification()
                
                if let task = backgroundTaskID {
                    UIApplication.shared.endBackgroundTask(task)
                    backgroundTaskID = .invalid
                }
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        saveState() // 상태 저장
    }
    
    func updateProgress() {
        // 남은 시간에 비례하여 progress 값을 업데이트
        self.progress = CGFloat(self.timeRemaining) / CGFloat(self.time.convertedSeconds)
    }
}
