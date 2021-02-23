//
//  JHSpeech.swift
//  LotteAcropolis
//
//  Created by neighbor on 2018. 11. 15..
//  Copyright © 2018년 neighbor. All rights reserved.
//

import UIKit
import Speech

protocol JHSpeechCallback: class {
    // 시작
    func start()
    // 종료
    func end()
    // 문자
    func bestTranscription(message: String)
    // 에러
    func speechError()
    // 메터
    func audioMeterDidUpdate(average: Float, peak: Float, interval: TimeInterval)
}


class JHSpeech: NSObject, SFSpeechRecognizerDelegate {
    
    weak var callback: JHSpeechCallback?
    
    open var locale:String = "ko-KR"
    
    private var speechRecognizer: SFSpeechRecognizer? // = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 음성파장
    private var audioRecorder: AVAudioRecorder?
    
    
    override init() {
        print("init")
                
        let recorderSettings: [String: AnyObject] = [AVSampleRateKey: 44100.0 as AnyObject,
                                                     AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
                                                     AVNumberOfChannelsKey: 1 as AnyObject,
                                                     AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue as AnyObject]
        
        // 임시 저장 파일 경로
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let url = URL(fileURLWithPath: directory).appendingPathComponent("recording.m4a") // 파일명
        audioRecorder = try? AVAudioRecorder(url: url, settings: recorderSettings)
        audioRecorder?.isMeteringEnabled = true
    }
    
    open func isRunning() -> Bool {
        return audioEngine.isRunning
    }
    
    open func speechToText(_ flag: Bool) {
        
        if self.speechRecognizer == nil {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: locale))
            self.speechRecognizer?.delegate = self
        }
        
        // 음성을 호출 합니다.
        if flag {
            if audioEngine.isRunning == false {
                callback?.start()
                startRecording()
            }
        }else{
            if audioEngine.isRunning {
                callback?.end()
                stopRecording()
            }
        }
        
    }
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        //레코딩 종료
        audioRecorder?.stop()
        // 메터링 종료
        stopMetering()
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
    }
    
    private func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        //--------------------------------------------------
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: .measurement, options: [])
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        //--------------------------------------------------
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let str = result?.bestTranscription.formattedString {
                // 문자 제공
                self.callback?.bestTranscription(message: str)
                
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                // 레코딩 종료
                self.audioRecorder?.stop()
                // 메터링 종료
                self.stopMetering()

                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.callback?.end()
                
                // 음성인식을 사용할 수 없습니다.
                // self.callback?.speechError()
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        // 레코딩 준비
        audioRecorder?.prepareToRecord()
        
        do {
            try audioEngine.start()
            // 레코딩 시작
            audioRecorder?.record()
            // 메터링 시작
            startMetering()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("speechRecognizer available")
        if available {
            self.callback?.start()
        } else {
            self.callback?.end()
        }
    }
    
    // MARK: - Metering
    // 애플리케이션에서 드로잉을 디스플레이의 주사율와 동기화 할 수 있게 해주는 타이머 객체
    fileprivate var link: CADisplayLink?
    let correction: Float = 100.0
    // Configuration Settings
    private let updateInterval = 0.1

    // Internal Timer to schedule updates from player
    private var timer: Timer?
    
    @objc func updateMeter() {
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        
        // NOTE: seems to be the approx correction to get real decibels
        let average = recorder.averagePower(forChannel: 0) + correction
        let peak = recorder.peakPower(forChannel: 0) + correction
        
        self.callback?.audioMeterDidUpdate(average: average, peak: peak, interval: recorder.currentTime)
    }
    
    
    fileprivate func startMetering() {
//        link = CADisplayLink(target: self, selector: #selector(updateMeter))
//        link?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
        timer = Timer.scheduledTimer(timeInterval: updateInterval,
                                     target: self,
                                     selector: #selector(self.updateMeter),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    fileprivate func stopMetering() {
//        link?.invalidate()
//        link = nil
        guard timer != nil, timer!.isValid else {
            return
        }

        timer?.invalidate()
        timer = nil
    }
}
