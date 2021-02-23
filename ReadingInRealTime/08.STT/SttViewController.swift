//
//  SttViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/23.
//

import UIKit

class SttViewController: UIViewController {

    @IBOutlet weak var textRect: UITextView!
    @IBOutlet weak var buttonMice: UIButton!
    @IBOutlet weak var guideLabel: UILabel!
    
    private var jhSpeech =  JHSpeech()
    
    // 둠칫둠칫
    @IBOutlet weak var meterView: AudioPowerVisualizerView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "STT 애플"
        
        textRect.text = ""
        guideLabel.text = ""
        
        jhSpeech.callback = self
        
        meterView.layer.cornerRadius = 50
    }
    
    deinit {
        print("SttViewController deinit")
    }
    
    @IBAction func actionMic(_ sender: Any) {
        
        if jhSpeech.isRunning() {
            guideLabel.text = ""
            meterView.backgroundColor = .orange
            jhSpeech.speechToText(false)
        } else {
            guideLabel.text = "한글 음성인식 입니다."
            meterView.backgroundColor = .red
            jhSpeech.speechToText(true)
        }
    }
    
}

extension SttViewController : JHSpeechCallback{
    
    func start() {
        self.textRect.text = ""
        meterView.isPlaying = jhSpeech.isRunning()
    }
    
    func end() {
        meterView.isPlaying = jhSpeech.isRunning()
    }
    
    func speechError() {
        meterView.isPlaying = jhSpeech.isRunning()
        print("ERROR 음성인식 에러.")
    }
    
    func bestTranscription(message: String) {
        
        self.textRect.text = message
        
        // 커서를 맨 아래로.
        let location = self.textRect.text.count - 1
        let bottom = NSMakeRange(location, 1)
        self.textRect.scrollRangeToVisible(bottom)
    }
    
    func audioMeterDidUpdate(average: Float, peak: Float, interval: TimeInterval) {
        if peak < 68 {
            return
        }
        print("average = \(average),    peak = \(peak)")
        meterView.updateMeters(power: CGFloat(peak))
    }
}
