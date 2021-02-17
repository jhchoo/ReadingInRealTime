//
//  RealtimeOcrAppleViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/17.
//

import UIKit
import Foundation
import AVFoundation
import Vision

class RealtimeOcrAppleViewController: UIViewController {
    
    // MARK: - UI 개체
    @IBOutlet weak var previewView: HKPreviewView!

    // MARK: - Capture 관련 개체
    private let captureSession = AVCaptureSession()
    // 세션 버퍼의 비율
    var bufferAspectRatio: Double!
    
    // 전용 쓰레드
    let captureSessionQueue = DispatchQueue(label: "com.jhchoo.ReadingInRealTime.CaptureSessionQueue")
    
    var videoDataOutput = AVCaptureVideoDataOutput()
    let videoDataOutputQueue = DispatchQueue(label: "com.jhchoo.ReadingInRealTime.VideoDataOutputQueue")
    
    // 카메라 디바이스
    var captureDevice: AVCaptureDevice?
    
    // 기기 방향. 방향이 지원되는 다른 방향으로 변경 될 때마다 업데이트됩니다.
    var currentOrientation = UIDeviceOrientation.portrait
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 미리보기보기를 설정합니다.
        previewView.session = captureSession
        
        // 뷰 설정
        initCutout()
        
        
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
    
    deinit {
        print("RealtimeOcrAppleViewController deinit")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 화면구성
        updateCutout()
    }
    
    // 가로세로 회전
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // 새 방향이 가로 또는 세로 인 경우에만 현재 방향을 변경하십시오.
        // 당신은 평평하거나 알려지지 않은 것에 대해 아무것도 할 수 없습니다.
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
            currentOrientation = deviceOrientation
        }
        
        // 미리보기 레이어에서 장치 방향을 처리합니다.
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            if let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) {
                videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            }
        }
        
        // 방향 변경 : 새로운 관심 영역 (ROI) 파악.
        calculateRegionOfInterest()
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
                
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Could not create device input.")
            return
        }
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        
        // 비디오 데이터 출력을 구성합니다.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
       
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            // NOTE:
            // 여기에는 절충안이 있습니다. 안정화를 활성화하면
            // 시간적으로 더 안정적인 결과를 제공하고 인식기가 수렴하는 데 도움이됩니다.
            // 하지만 활성화 된 경우 VideoDataOutput 버퍼는
            // 화면에 표시된 것과 일치하므로 경계 상자를 그리기가 매우 어렵습니다.
            // 이 앱에서 비활성화하면 감지 된 경계 상자를 화면에 그릴 수 있습니다.
            videoDataOutput.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = .off
        } else {
            print("Could not add VDO output")
            return
        }
        
        // 매우 작은 텍스트에 집중할 수 있도록 줌 및 자동 초점을 설정합니다.
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.videoZoomFactor = 1 // 장치에서 캡처 한 이미지의 자르기 및 확대를 제어하는 ​​값입니다. 클수록 확대 2 까지 가능 // 2배 확대
            captureDevice.autoFocusRangeRestriction = .near
            captureDevice.unlockForConfiguration()
        } catch {
            print("Could not set zoom level due to error: \(error)")
            return
        }
        
        captureSession.startRunning()
    }
    //==================
    // 출력 뷰
    @IBOutlet weak var cutoutView: UIView!
    @IBOutlet weak var numberView: UILabel!
    
    var maskLayer = CAShapeLayer()
    
    // MARK: - Region of interest (ROI) 관심영역 and 텍스트 방향
    // 인식이 실행되어야하는 비디오 데이터 출력 버퍼의 영역입니다.
    // 미리보기 레이어의 경계가 알려지면 다시 계산됩니다.
    var regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    // 관심 영역에서 검색 할 텍스트 방향입니다.
    var textOrientation = CGImagePropertyOrientation.up
    
    // MARK: - 좌표 변환
    // 왼쪽 하단 좌표를 왼쪽 상단으로 변환합니다.
    var bottomToTopTransform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
    // UI 방향에서 버퍼 방향으로 변환합니다.
    var uiRotationTransform = CGAffineTransform.identity
    // ROI의 좌표를 전역 좌표로 변환합니다 (여전히 정규화 됨).
    var roiToGlobalTransform = CGAffineTransform.identity
    // Vision -> AVF 좌표 변환.
    var visionToAVFTransform = CGAffineTransform.identity

    // 초기화 설정
    func initCutout() {
        cutoutView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = .evenOdd
        cutoutView.layer.mask = maskLayer // 마스크 부분을 빈 공간으로 한다.
    }
    
    // 화면구성, 매번 다시 그려 줄 부분
    func updateCutout() {
        // 컷 아웃이 레이어 좌표에서 끝나는 위치를 파악합니다.
        let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
        let cutout = previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: regionOfInterest.applying(roiRectTransform))
        
        // Create the mask.
        let path = UIBezierPath(rect: cutoutView.frame)
        path.append(UIBezierPath(rect: cutout))
        maskLayer.path = path.cgPath
        
        // Move the number view down to under cutout.
        var numFrame = cutout
        numFrame.origin.y += numFrame.size.height
        numberView.frame = numFrame
    }
    
    //==================
        
    //==================
    func calculateRegionOfInterest() {
        // 가로 방향에서 원하는 ROI는 버퍼 너비와 높이의 비율로 지정됩니다.
        // UI가 세로로 회전 할 때 세로 크기를 동일하게 유지합니다 (버퍼 픽셀 단위).
        // 또한 가로 크기를 최대 비율까지 동일하게 유지하십시오.
        
        let desiredHeightRatio = 0.3 //0.15
        let desiredWidthRatio = 1.0 //0.6
        let maxPortraitWidth = 1.0 //0.8
        
        // Figure out size of ROI.
        let size: CGSize
        if currentOrientation.isPortrait || currentOrientation == .unknown {
            size = CGSize(width: min(desiredWidthRatio * bufferAspectRatio, maxPortraitWidth), height: desiredHeightRatio / bufferAspectRatio)
        } else {
            size = CGSize(width: desiredWidthRatio, height: desiredHeightRatio)
        }
        // Make it centered.
        regionOfInterest.origin = CGPoint(x: (1 - size.width) / 2, y: (1 - size.height) / 2)
        regionOfInterest.size = size
        
        // ROI가 변경되었습니다. 변환을 업데이트하십시오.
        setupOrientationAndTransform()
        
        // 새로운 ROI와 일치하도록 컷 아웃을 업데이트합니다.
        DispatchQueue.main.async {
            // 컷 아웃을 업데이트하기 전에 다음 실행주기를 기다리십시오.
            // 이렇게하면 미리보기 레이어가 이미 새로운 방향을 갖게됩니다.
            self.updateCutout()
        }
    }
    
    func setupOrientationAndTransform() {
        // Recalculate the affine transform between Vision coordinates and AVF coordinates.
        
        // Compensate for region of interest.
        let roi = regionOfInterest
        roiToGlobalTransform = CGAffineTransform(translationX: roi.origin.x, y: roi.origin.y).scaledBy(x: roi.width, y: roi.height)
        
        // Compensate for orientation (buffers always come in the same orientation).
        switch currentOrientation {
        case .landscapeLeft:
            textOrientation = CGImagePropertyOrientation.up
            uiRotationTransform = CGAffineTransform.identity
        case .landscapeRight:
            textOrientation = CGImagePropertyOrientation.down
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 1).rotated(by: CGFloat.pi)
        case .portraitUpsideDown:
            textOrientation = CGImagePropertyOrientation.left
            uiRotationTransform = CGAffineTransform(translationX: 1, y: 0).rotated(by: CGFloat.pi / 2)
        default: // We default everything else to .portraitUp
            textOrientation = CGImagePropertyOrientation.right
            uiRotationTransform = CGAffineTransform(translationX: 0, y: 1).rotated(by: -CGFloat.pi / 2)
        }
        
        // Full Vision ROI to AVF transform.
        visionToAVFTransform = roiToGlobalTransform.concatenating(bottomToTopTransform).concatenating(uiRotationTransform)
    }
    //==================

    // VisionViewController 비젼 뷰에서 사용 
    func showString(string: String) {
        // Found a definite number.
        // Stop the camera synchronously to ensure that no further buffers are
        // received. Then update the number view asynchronously.
        captureSessionQueue.sync {
            // self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.numberView.text = string
                self.numberView.isHidden = false
            }
        }
    }
    
    
    
}

extension RealtimeOcrAppleViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // This is implemented in VisionViewController.
    }
}

// MARK: - Utility extensions
extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
}
