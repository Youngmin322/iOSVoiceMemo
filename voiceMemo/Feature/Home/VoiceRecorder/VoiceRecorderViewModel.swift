//
//  VoiceRecorderViewModel.swift
//  voiceMemo
//

import AVFoundation
import Speech

class VoiceRecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate, SFSpeechRecognizerDelegate {
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
    
    /// STT 기능
    @Published var transcribedText: String = ""  // 인식된 텍스트를 저장
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    let audioEngine = AVAudioEngine()
    
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

extension VoiceRecorderViewModel {
    func requestSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("User authorized speech recognition")
                case .denied, .restricted, .notDetermined:
                    self.displayAlert(message: "음성 인식 권한이 필요합니다.")
                @unknown default:
                    fatalError()
                }
            }
        }
    }
}

extension VoiceRecorderViewModel {
    func startSpeechRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            displayAlert(message: "음성 인식 서비스가 현재 사용 불가능합니다.")
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            displayAlert(message: "오디오 엔진을 시작할 수 없습니다.")
            return
        }

        speechRecognizer.recognitionTask(with: request) { result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                self.transcribedText = transcribedText
            } else if let error = error {
                self.displayAlert(message: "음성 인식 중 오류가 발생했습니다: \(error.localizedDescription)")
            }
        }
    }
    
    func stopSpeechRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request.endAudio()
    }
}

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
    
    func renameFile(at url: URL, to newName: String) {
        let fileManager = FileManager.default
        let newURL = getDocumentsDirectory().appendingPathComponent(newName)
        
        do {
            try fileManager.moveItem(at: url, to: newURL)
            if let index = recordedFiles.firstIndex(of: url) {
                recordedFiles[index] = newURL
            }
            if selectedRecoredFile == url {
                selectedRecoredFile = newURL
            }
            displayAlert(message: "파일 이름이 성공적으로 변경되었습니다.")
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
            startSpeechRecognition()
        } else if isRecording {
            stopRecording()
            stopSpeechRecognition()
        } else {
            startRecording()
            startSpeechRecognition()
        }
    }
    
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
        } catch {
            self.displayAlert(message: "음성 메모 녹음 중 오류가 발생했습니다.")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        self.recordedFiles.append(self.audioRecorder!.url)
        self.isRecording = false
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
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
    
    private func updateCurrentTime() {
        self.playedTime = audioPlayer?.currentTime ?? 0
    }
    
    private func stopPlaying() {
        audioPlayer?.stop()
        playedTime = 0
        self.progressTimer?.invalidate()
        self.isPlaying = false
        self.isPaused = false
    }
    
    func pausePlaying() {
        audioPlayer?.pause()
        self.isPaused = true
    }
    
    func resumePlaying() {
        audioPlayer?.play()
        self.isPaused = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.isPlaying = false
        self.isPaused = false
    }
    
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
    
    func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("마이크 권한이 허용되었습니다.")
                self.requestSpeechRecognitionAuthorization()
            } else {
                print("마이크 권한이 거부되었습니다.")
                self.displayAlert(message: "마이크 사용 권한이 필요합니다. 설정에서 권한을 허용해주세요.")
            }
        }
    }
    
}
