//
//  ScannerViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/17.
//

import UIKit
import AVFoundation

class ScannerViewController: UIViewController {
    
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var qrcodeFrameView: UIView?
    
    @IBOutlet weak var viewBox: UIView!
    @IBOutlet weak var labelBox: UIView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var retry: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "바코드&QR"
        
        viewBox.layer.borderWidth = 4
        viewBox.layer.borderColor = UIColor.yellow.cgColor
        viewBox.layer.cornerRadius = 16
        labelBox.layer.cornerRadius = 5
        retry.isHidden = true
        
        setCapture()
    }
    
    deinit {
        print("ScannerViewController deinit")
    }
    
    func setCapture() {
        
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
            
            self.view.bringSubviewToFront(self.viewBox)
            self.view.bringSubviewToFront(self.labelBox)
            self.view.bringSubviewToFront(self.retry)
            
            self.labelName.text = "인식중"
        }
    }
    
    @IBAction func actionRetry(_ sender: Any) {
        retry.isHidden = true
        
        self.labelName.text = "인식중"
        
        self.captureSession.startRunning()
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        guard let first = metadataObjects.first,
              let readableObject = first as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            self.labelName.text = "인식중"
            return
        }
        
        // 샘플에서 찾은 바코드 타입, 종류가 많다.
        // org.gs1.EAN-13
        print("바코드 .type = \(readableObject.type)")
        
        found(code: stringValue)
        
        
    }
    
    func found(code: String) {
        self.labelName.text = code
        
        // 캡쳐 중지
        self.captureSession.stopRunning()
        
        self.retry.isHidden = false
    }
    
}
