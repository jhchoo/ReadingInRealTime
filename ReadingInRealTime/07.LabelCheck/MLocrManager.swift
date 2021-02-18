//
//  MLocrManager.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/18.
//

import UIKit
import Foundation
import AVFoundation
import Vision

// MARK: 바코드 값 전달
@objc protocol MLocrManagerDelegate {
    // 바코드 또는 QR을 찾은경우
    func stringFound(array: [String])
}

class MLocrManager: NSObject {
    // MARK: - 변수
    // static let shared = MLocrManager()
    
    private weak var delegate: MLocrManagerDelegate?
    private var isCapturePossible: Bool = false
    
    private var preview: HKPreviewView!
    private var coutview: UIView!
    
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

    
    // MARK: - 비디오
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
    
    
    func setupCamera(preview: HKPreviewView, coutview: UIView, delegate: MLocrManagerDelegate) {

        self.preview = preview
        self.coutview = coutview
        self.delegate = delegate
        
        // 미리보기보기를 설정합니다.
        self.preview.session = captureSession
        
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
        
        initVNRecognizeTextRequest()
    }

    // 초기화 설정
    func initCutout() {
        self.coutview.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = .evenOdd
        self.coutview.layer.mask = maskLayer // 마스크 부분을 빈 공간으로 한다.
    }
    
    // 화면구성, 매번 다시 그려 줄 부분
    func updateCutout() {
        // 컷 아웃이 레이어 좌표에서 끝나는 위치를 파악합니다.
        let roiRectTransform = bottomToTopTransform.concatenating(uiRotationTransform)
        let cutout = self.preview.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: regionOfInterest.applying(roiRectTransform))
        
        // Create the mask.
        let path = UIBezierPath(rect: self.coutview.frame)
        path.append(UIBezierPath(rect: cutout))
        maskLayer.path = path.cgPath
    }
    
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
        
        // 캡쳐여부 결정
        self.isCapturePossible = true
    }
    
    public func toggleRunning() -> Bool {
        if !self.isCapturePossible { return false }
        
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
            return false
        } else {
            self.captureSession.startRunning()
            return true
        }
    }
    
    public func startRunning() {
        if !self.isCapturePossible { return }
        
        if self.captureSession.isRunning {
            return
        }
        
        // 비디오 캡쳐 시작
        self.captureSession.startRunning()
    }
    
    public func stopRunning() {
        if !self.isCapturePossible { return }
        
        if !self.captureSession.isRunning {
            return
        }
        
        // 비디오 캡쳐 종료
        self.captureSession.stopRunning()
        // 디텍팅 상자 제거
        show(boxGroups: [])
    }
    
    //==================
    // 텍스트 인식
    var txtRequest: VNRecognizeTextRequest!
    var boxLayer = [CAShapeLayer]()
    var uiHold: Bool = false
    
    func initVNRecognizeTextRequest() {
        
        // ViewController가 카메라를 설정하도록하기 전에 비전 요청을 설정하십시오.
        // 첫 번째 버퍼가 수신 될 때 존재하도록합니다.
        txtRequest = VNRecognizeTextRequest{ [weak self] (req, err) in
            if let err = err as NSError? {
                fatalError("\n\n\n\n\n @@@@@@@  error \(err), \(err.userInfo)")
            }
            
            self?.recognizeTextHandler(request: req, error: err)
        }
        
        // 이걸 안하면, Error computing NN outputs 오류가 생길 수 있다.
        txtRequest.usesCPUOnly = true
        
        // VNRecognizeTextRequestRevision2
        // 정확한 인식 수준에서 영어, 중국어, 포르투갈어, 프랑스어, 이탈리아어, 독일어 및 스페인어를 지원합니다. 7개 언어
        // 사용하여 플레이 그라운드에서 확인할 수 있습니다.
        // try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: 2)
        
        // 빠른속도
        // request.recognitionLevel = .fast
        // 높은 정확성
        txtRequest.recognitionLevel = .accurate
        
        // 언어 인식 우선순위 설정
        txtRequest.recognitionLanguages = ["en-US"] //  en-GB (영국식 영어), en-US (미국식 영어) , en-CA (캐나다식 영어)
        txtRequest.usesLanguageCorrection = true
    }
}

extension MLocrManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // 최대 속도를 위해 관심 영역에서만 실행.
            txtRequest.regionOfInterest = regionOfInterest
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
            do {
                try requestHandler.perform([txtRequest])
            } catch {
                print(error)
            }
        }
    }
}

// 머신러닝
extension MLocrManager {
    
    // 시각 인식 핸들러.
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        if uiHold {
            return
        }
        self.uiHold = true
        
        var numbers = [String]()
        var redBoxes = [CGRect]() // Shows all recognized text lines
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            self.uiHold = false
            show(boxGroups: [])
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            
            // 두글자 이상만 넣자.
            if candidate.string.count <= 2 {
                continue
            }
            
            redBoxes.append(visionResult.boundingBox)
            numbers.append(candidate.string)
            
            print("검색문자 = \(candidate.string)")
            
        }
        
        // 두글자 이하 체크 후 글자가 없으면 종료
        if numbers.count == 0 {
            self.uiHold = false
            show(boxGroups: [])
            return
        }
        
        // 발견 된 영역에 박스를 그려 줍니다.
        show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes)])
        
        // 발견된 문자 리스트 전달
        self.delegate?.stringFound(array: numbers)
        
        self.uiHold = false
    }
    
    // MARK: - 경계 상자 그리기
    
    // 화면에 상자를 그립니다. 기본 대기열에서 호출해야합니다.
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 3
        layer.frame = rect
        boxLayer.append(layer)
        self.preview.videoPreviewLayer.insertSublayer(layer, at: 1)
    }
    
    // 그려진 상자를 모두 제거하십시오. 메인 대기열에서 호출되어야합니다.
    func removeBoxes() {
        for layer in boxLayer {
            layer.removeFromSuperlayer()
        }
        boxLayer.removeAll()
    }
    
    typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
    
    // 색상 상자 그룹을 그립니다.
    func show(boxGroups: [ColoredBoxGroup]) {
        DispatchQueue.main.async {
            let layer = self.preview.videoPreviewLayer
            self.removeBoxes()
            for boxGroup in boxGroups {
                let color = boxGroup.color
                for box in boxGroup.boxes {
                    let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    self.draw(rect: rect, color: color)
                }
            }
        }
    }
}
