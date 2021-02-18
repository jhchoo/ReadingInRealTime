//
//  BarcodeManager.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/17.
//

import Foundation
import UIKit
import AVFoundation

// MARK: 바코드 값 전달
@objc protocol BarcodeManagerDelegate {
    // 바코드 또는 QR을 찾은경우
    func codeFound(code: String)
}

class BarcodeManager: NSObject {
    // MARK: - 변수
    // static let shared = BarcodeManager()

    private var view: UIView!
    private weak var delegate: BarcodeManagerDelegate?
    private var coutview: UIView!
    
    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isCapturePossible: Bool = false
    
    var maskLayer = CAShapeLayer()
    
    public func setupCamera(preview: UIView, coutview: UIView, delegate: BarcodeManagerDelegate) {
        // 필수
        self.view = preview
        self.coutview = coutview
        self.delegate = delegate
        
        initCutout()
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("ERRER 비디오 기능 불가")
                return
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                
                if (self.captureSession.canAddInput(videoInput)) {
                    self.captureSession.addInput(videoInput)
                } else {
                    print("ERRER 캡쳐 세션 인풋 불가")
                    return
                }
            } catch {
                print("ERRER 비디오 인풋 불가")
                return
            }
            
            // 아웃풋을 만들고 델리게이트를 열결한다.
            let metadataOutput = AVCaptureMetadataOutput()
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            if (self.captureSession.canAddOutput(metadataOutput)) {
                self.captureSession.addOutput(metadataOutput)
                
                // 메타 데이터 타입을 선택한것만 찾는다.
                // 타입을 정확히 알수 없으니 모든 타입으로 정한다.
                metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes // [.ean8, .ean13, .pdf417, .qr]
            } else {
                print("ERRER 캡쳐 세션 아웃풋 불가")
                return
            }
            
            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer.frame = self.view.layer.bounds
            self.previewLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(self.previewLayer)
            
            // 비디오 캡쳐 시작
            self.captureSession.startRunning()
            
            // 캡쳐여부 결정
            self.isCapturePossible = true
        }
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
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let cutout = CGRect(x: 30, y: 30, width: self.coutview.frame.width - 60, height: self.coutview.frame.height - 60)
            let path = UIBezierPath(rect: self.coutview.frame)
            path.append(UIBezierPath(rect: cutout))
            self.maskLayer.path = path.cgPath
        }
    }
    
    public func updatePreview() {
        if self.previewLayer == nil || self.view == nil {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.previewLayer.frame = self.view.layer.bounds
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
    }
}

extension BarcodeManager: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        guard let first = metadataObjects.first,
              let readableObject = first as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            print("ERROR")
            return
        }
        
        // 샘플에서 찾은 바코드 타입, 종류가 많다.
        // org.gs1.EAN-13
        print("type = \(readableObject.type), code = \(stringValue)")
        
        // 찾은 결과값 전달
        self.delegate?.codeFound(code: stringValue)
        // 캡쳐 중지
        self.captureSession.stopRunning()
    }
}
