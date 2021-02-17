//
//  VisionViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/17.
//

import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: RealtimeOcrAppleViewController {
    
    var txtRequest: VNRecognizeTextRequest?
    // 임시 문자열 추적기
    let numberTracker = StringTracker()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "실시간 글자인식"
        
        // ViewController가 카메라를 설정하도록하기 전에 비전 요청을 설정하십시오.
        // 첫 번째 버퍼가 수신 될 때 존재하도록합니다.
        txtRequest = VNRecognizeTextRequest{ [weak self] (req, err) in
            self?.recognizeTextHandler(request: req, error: err)
        }
            
        // VNRecognizeTextRequestRevision2
        // 정확한 인식 수준에서 영어, 중국어, 포르투갈어, 프랑스어, 이탈리아어, 독일어 및 스페인어를 지원합니다. 7개 언어
        // 사용하여 플레이 그라운드에서 확인할 수 있습니다.
        // try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: 2)
        
        guard let request = txtRequest else {
            return
        }
        
        // 빠른속도
        // request.recognitionLevel = .fast
        // 높은 정확성
        request.recognitionLevel = .accurate
        
        // 언어 인식
        request.recognitionLanguages = ["en-US"] //  en-GB (영국식 영어), en-US (미국식 영어) , en-CA (캐나다식 영어)
        request.usesLanguageCorrection = true
    }
    
    deinit {
        print("VisionViewController deinit")
    }

    // captureOutput 오버라이딩 해서 버퍼를 확인하고 그린다.
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            
            guard let request = txtRequest else {
                return
            }
            
            // 최대 속도를 위해 관심 영역에서만 실행.
            request.regionOfInterest = regionOfInterest
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    // 시각 인식 핸들러.
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        var numbers = [String]()
        var redBoxes = [CGRect]() // Shows all recognized text lines
        
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let maximumCandidates = 1
        
        for visionResult in results {
            guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
            
            redBoxes.append(visionResult.boundingBox)
            numbers.append(candidate.string)
            
            print("검색문자 = \(candidate.string)")
            
        }
        
        // 발견 된 영역에 박스를 그려 줍니다.
        show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes)])
        
        var labelText: String = ""
        for string in numbers {
            labelText = labelText + string + ",\n"
        }
        
        showString(string: labelText)
        
    }
    
    // MARK: - 경계 상자 그리기
    
    // 화면에 상자를 그립니다. 기본 대기열에서 호출해야합니다.
    var boxLayer = [CAShapeLayer]()
    func draw(rect: CGRect, color: CGColor) {
        let layer = CAShapeLayer()
        layer.opacity = 0.5
        layer.borderColor = color
        layer.borderWidth = 3
        layer.frame = rect
        boxLayer.append(layer)
        previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
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
            let layer = self.previewView.videoPreviewLayer
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
