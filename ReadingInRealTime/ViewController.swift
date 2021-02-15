//
//  ViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/15.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    // MARK: - UI 개체
    @IBOutlet weak var previewView: PreviewView!
    // MARK: - Capture 관련 개체
    private let captureSession = AVCaptureSession()
    // 전용 쓰레드
    let captureSessionQueue = DispatchQueue(label: "com.jhchoo.ReadingInRealTime.CaptureSessionQueue")
    // 카메라 디바이스
    var captureDevice: AVCaptureDevice?
    
    // 출력 뷰
    @IBOutlet weak var cutoutView: UIView!
    var maskLayer = CAShapeLayer()
    
    // MARK: - Coordinate transforms
    var bufferAspectRatio: Double!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 미리보기보기를 설정합니다.
        previewView.session = captureSession
        
        // cutoutView 뷰 설정
        cutoutView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = .evenOdd
        cutoutView.layer.mask = maskLayer // 마스크 부분을 빈 공간으로 한다.
        
        
        // 캡처 세션 시작 is a blocking call. 다음을 사용하여 설정 수행
        // 메인 스레드 차단을 방지하기위한 전용 직렬 디스패치 큐
        captureSessionQueue.async {
            self.setupCamera()
            
            // 카메라가 설정되었으므로 관심 영역을 계산합니다.
            DispatchQueue.main.async {
                // Figure out initial ROI.
                self.calculateRegionOfInterest()
            }
        }
    }

    //==================
    func setupCamera() {
        // builtInWideAngleCamera 와이드 앵글 카메라,
        // AVMediaType.video 비디오 캡쳐 모드
        // .back 후면 카메라 사용
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            print("Could not create capture device.")
            return
        }
        
        self.captureDevice = captureDevice
        
        // NOTE:
        // 4k 버퍼를 요청하면 더 작은 텍스트를 인식 할 수 있지만 더 많은 전력을 소비합니다.
        // 유지하는 데 필요한 가장 작은 버퍼 크기를 사용하십시오.
        // 다운 배터리 사용량.
        if captureDevice.supportsSessionPreset(.hd4K3840x2160) { // 4K를 지원하는 카메라는 4K를 사용한다.
            captureSession.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
            bufferAspectRatio = 3840.0 / 2160.0
        } else {    // 아니면 일반크기
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
            bufferAspectRatio = 1920.0 / 1080.0
        }
        
        
        
    }
    //==================
    
    
    
    
    //==================
    func calculateRegionOfInterest() {
        
    }
    //==================
}

