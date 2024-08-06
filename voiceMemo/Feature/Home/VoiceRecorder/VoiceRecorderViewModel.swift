//
//  VoiceRecorderViewModel.swift
//  voiceMemo
//

import AVFoundation
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(ActivityKit)
@available(iOS 16.1, *) // iOS 16.1 이상에서 사용 가능한 다이나믹 아일랜드 관련 구조체
struct VoiceRecorderAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var recordingTime: TimeInterval
    }

    var name: String
}
#endif

class VoiceRecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isDisplayRemoveVoiceRecorderAlert: Bool
    @Published var isDisplayAlert: Bool
    @Published var alertMessage: String
    
    /// 음성메모 녹음 관련 프로퍼티
    var audioRecorder: AVAudioRecorder?
    @Published var isRecording: Bool
    
    /// 음성메모 재생 관련 프로퍼티
    var audioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool
    @Published var isPaused: Bool
    @Published var playedTime: TimeInterval
    private var progressTimer: Timer?
    
    /// 음성메모된 파일
    var recordedFiles: [URL]
    
    /// 현재 선택된 음성메모 파일
    @Published var selectedRecoredFile: URL?
    
    /// 다이나믹 아일랜드 관련 프로퍼티
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    @Published var currentActivity: Activity<VoiceRecorderAttributes>?
    #endif
    private var recordingTimer: Timer?
    @Published var recordingTime: TimeInterval = 0
    
    /// 파일 이름 편집 관련 프로퍼티
    @Published var isEditingFileName: Bool = false
    @Published var editingFileName: String = ""
    @Published var playbackRate: Float = 1.0

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
    }
    
    init(
        isDisplayRemoveVoiceRecorderAlert: Bool = false,
        isDisplayErrorAlert: Bool = false,
        errorAlertMessage: String = "",
        isRecording: Bool = false,
        isPlaying: Bool = false,
        isPaused: Bool = false,
        playedTime: TimeInterval = 0,
        recordedFiles: [URL] = [],
        selectedRecoredFile: URL? = nil
    ) {
        self.isDisplayRemoveVoiceRecorderAlert = isDisplayRemoveVoiceRecorderAlert
        self.isDisplayAlert = isDisplayErrorAlert
        self.alertMessage = errorAlertMessage
        self.isRecording = isRecording
        self.isPlaying = isPlaying
        self.isPaused = isPaused
        self.playedTime = playedTime
        self.recordedFiles = recordedFiles
        self.selectedRecoredFile = selectedRecoredFile
    }
}

//음성 메모 셀 탭 처리
extension VoiceRecorderViewModel {
    func voiceRecordCellTapped(_ recordedFile: URL) {
        if selectedRecoredFile != recordedFile {
            stopPlaying()
            selectedRecoredFile = recordedFile
        }
    }
    
    func removeBtnTapped() {
        setIsDisplayRemoveVoiceRecorderAlert(true)
    }
    
    //음성 메모 파일 삭제
    func removeSelectedVoiceRecord() {
        guard let fileToRemove = selectedRecoredFile,
              let indexToRemove = recordedFiles.firstIndex(of: fileToRemove) else {
            displayAlert(message: "선택된 음성메모 파일을 찾을 수 없습니다.")
            return
        }
        
        do {
            try FileManager.default.removeItem(at: fileToRemove)
            recordedFiles.remove(at: indexToRemove)
            selectedRecoredFile = nil
            stopPlaying()
            displayAlert(message: "선택된 음성메모 파일을 성공적으로 삭제했습니다.")
        } catch {
            displayAlert(message: "선택된 음성메모 파일 삭제 중 오류가 발생했습니다.")
        }
    }
    
    // 알림 표시 관련 도우미 메서드들
    private func setIsDisplayRemoveVoiceRecorderAlert(_ isDisplay: Bool) {
        isDisplayRemoveVoiceRecorderAlert = isDisplay
    }
    
    private func setErrorAlertMessage(_ message: String) {
        alertMessage = message
    }
    
    private func setIsDisplayErrorAlert(_ isDisplay: Bool) {
        isDisplayAlert = isDisplay
    }
    
    private func displayAlert(message: String) {
        setErrorAlertMessage(message)
        setIsDisplayErrorAlert(true)
    }
    
    //파일 이름 수정
    func startEditingFileName(for file: URL) {
        editingFileName = file.lastPathComponent
        isEditingFileName = true
        selectedRecoredFile = file
    }

    // 수정한 파일 이름 저장
    func saveEditedFileName() {
        guard let selectedFile = selectedRecoredFile else { return }
        
        let newURL = selectedFile.deletingLastPathComponent().appendingPathComponent(editingFileName)
        
        do {
            try FileManager.default.moveItem(at: selectedFile, to: newURL)
            if let index = recordedFiles.firstIndex(of: selectedFile) {
                recordedFiles[index] = newURL
            }
            selectedRecoredFile = newURL
            isEditingFileName = false
        } catch {
            displayAlert(message: "파일 이름 변경 중 오류가 발생했습니다.")
        }
    }
}

// MARK: - 음성메모 녹음 관련
extension VoiceRecorderViewModel {
    func recordBtnTapped() {
        selectedRecoredFile = nil
        
        if isPlaying {
            stopPlaying()
            startRecording()
        } else if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    //녹음 시작
    private func startRecording() {
        let fileURL = self.getDocumentsDirectory().appendingPathComponent("새로운 녹음 \(self.recordedFiles.count + 1)")
        let settings = [
            AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey : 12000,
            AVNumberOfChannelsKey : 1,
            AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue
        ]
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.record)
            try AVAudioSession.sharedInstance().setActive(true)
            self.audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            self.audioRecorder?.record()
            self.isRecording = true
            #if canImport(ActivityKit)
            if #available(iOS 16.1, *) {
                startRecordingActivity()
            }
            #endif
            startRecordingTimer()
        } catch {
            self.displayAlert(message: "음성 메모 녹음 중 오류가 발생했습니다.")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        self.recordedFiles.append(self.audioRecorder!.url)
        self.isRecording = false
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            stopRecordingActivity()
        }
        #endif
        stopRecordingTimer()
    }
    
    // 문서 디렉토리 URL 가져오기
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // 녹음 타이머 시작
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingTime += 1
            #if canImport(ActivityKit)
            if #available(iOS 16.1, *) {
                self.updateRecordingActivity(time: self.recordingTime)
            }
            #endif
        }
    }

    // 녹음 타이머 중지
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0
    }
    
    // 다이나믹 아일랜드 관련 메서드들 (iOS 16.1 이상)
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    func startRecordingActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let attributes = VoiceRecorderAttributes(name: "음성 녹음")
        let contentState = VoiceRecorderAttributes.ContentState(recordingTime: 0)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print(error.localizedDescription)
        }
    }

    @available(iOS 16.1, *)
    func updateRecordingActivity(time: TimeInterval) {
        Task {
            await currentActivity?.update(
                using: VoiceRecorderAttributes.ContentState(recordingTime: time)
            )
        }
    }

    @available(iOS 16.1, *)
    func stopRecordingActivity() {
        Task {
            await currentActivity?.end(using: currentActivity?.contentState, dismissalPolicy: .immediate)
        }
    }
    #endif
}

// MARK: - 음성메모 재생 관련
extension VoiceRecorderViewModel {
    func startPlaying(recordingURL: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            self.isPlaying = true
            self.isPaused = false
            self.progressTimer = Timer.scheduledTimer(
                withTimeInterval: 0.1,
                repeats: true
            ) { _ in
                self.updateCurrentTime()
            }
        } catch {
            displayAlert(message: "음성메모 재생 중 오류가 발생했습니다.")
        }
    }
    
    // 현재 재생 시간 업데이트
    private func updateCurrentTime() {
        self.playedTime = audioPlayer?.currentTime ?? 0
    }
    
    // 재생 중지
    private func stopPlaying() {
        audioPlayer?.stop()
        playedTime = 0
        self.progressTimer?.invalidate()
        self.isPlaying = false
        self.isPaused = false
    }
    
    // 재생 일시정지
    func pausePlaying() {
        audioPlayer?.pause()
        self.isPaused = true
    }
    
    // 재개
    func resumePlaying() {
        audioPlayer?.play()
        self.isPaused = false
    }
    
    // 재생 완료 시 호출되는 델리게이트 메서드
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.isPlaying = false
        self.isPaused = false
    }
    
    // 파일 정보 가져오기
    func getFileInfo(for url: URL) -> (Date?, TimeInterval?) {
        let fileManager = FileManager.default
        var creationDate: Date?
        var duration: TimeInterval?
        
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: url.path)
            creationDate = fileAttributes[.creationDate] as? Date
        } catch {
            displayAlert(message: "선택된 음성메모 파일 정보를 불러올 수 없습니다.")
        }
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer.duration
        } catch {
            displayAlert(message: "선택된 음성메모 파일의 재생 시간을 불러올 수 없습니다.")
        }
        
        return (creationDate, duration)
    }
    
    
}
