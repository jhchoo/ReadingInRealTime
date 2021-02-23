//
//  AppleMachineViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/23.
//

// 오브젝트 디텍트 머신러닝 데이터 사용법은 간단하다.
// 데이터를 만드는 것이 문제.
// 실제 사용하는 환경과 같은 데이터가 많이 모여 있어야 한다.

import UIKit
import AVKit
import Vision
import CoreML

struct FindItem {
    var title: String
    var rect: CGRect
}

class AppleMachineViewController: UIViewController {
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var findLabel: UILabel!
        
    var visionModel: VNCoreMLModel?
    
    var isHold: Bool = false
    
    var findData = [String:FindItem]()
    var dataClearCount: Int = 20

    private let animalRecognitionWorkQueue = DispatchQueue(label: "PetClassifierRequest", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "애플 머신러닝"
        // Do any additional setup after loading the view.
        
        
        let config = MLModelConfiguration()
        config.computeUnits = .all

        guard let coreMLModel: MLModel = try? LabelObjectDetector.init(configuration: config).model else {
            return
        }
        do {
            visionModel = try VNCoreMLModel(for: coreMLModel)
        } catch {
            
        }
        
        
        // 카메라 시작
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let previewLayer = previewLayer {
            previewLayer.videoGravity = .resizeAspect
            container.layer.addSublayer(previewLayer)
        }
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue") )
        captureSession.addOutput(dataOutput)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        
        guard let previewLayer = previewLayer else {
            return
        }
        
        previewLayer.frame = container.frame
    
    }
    
    
}

extension AppleMachineViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        connection.videoOrientation = .portrait
        connection.preferredVideoStabilizationMode = .auto // 영상 흔들림 방지
        
        if self.isHold == true {
            return
        }
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let bufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let bufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        guard let visionModel = visionModel else {
            return
        }
        
        // VNRecognizeTextRequest
        
        
        let request = VNCoreMLRequest(model: visionModel) { (vnRequest, error) in
            
            // VNClassificationObservation
            // VNRecognizedObjectObservation
            
            guard let results = vnRequest.results as? [VNRecognizedObjectObservation] else {
                //print("Model failed to load image")
                return
            }
            
            //print("results cnt \(results.count)")
            if results.count == 0 {
                self.isHold = false
                
                self.dataClearCount -= 1
                if self.dataClearCount <= 0 {
                    self.findData.removeAll()
                    DispatchQueue.main.async {
                        self.findLabel.text = ""
                    }
                }
                return
            }
            
            self.dataClearCount = 20
            
            var animalCount: Int = 0
            var detectionString = ""
            
            //if let observation = results.last {
            for observation in results  {
                
                let obLabels = observation.labels
                animalCount = 0
                
                if let item = obLabels.first {
                    
                    // 오브젝트 찾는것은 OCR 참조 바람 이건 실패 함.
                    // Select only the label with the highest confidence
                    let objectBounds: CGRect = VNImageRectForNormalizedRect (observation.boundingBox, Int(bufferWidth), Int(bufferHeight))
                    print("objectBounds = \(objectBounds)")
                    //let shapeLayer = self.createRoundedRectLayerWithBounds (objectBounds)
                    //let textLayer = self.createTextSubLayerInBounds (objectBounds, identifier: item.identifier, confidence: item.confidence)
                    //.shapeLayer.addSublayer (textLayer)
                    //detectOverlay.addSublayer (shapeLayer)
                   
                    animalCount = animalCount + 1
                    
                    if item.identifier == "hankook_logo"{
                        // detectionString = detectionString + "hankook_logo \n"
                        self.findData["hankook_logo"] = FindItem(title: "한국타이어 라벨", rect: objectBounds)
                    }
                    else if item.identifier == "laufenn_logo"{
                        //detectionString = detectionString + "laufenn_logo \n"
                        self.findData["laufenn_logo"] = FindItem(title: "러핀 라벨", rect: objectBounds)
                    }
                    else if item.identifier == "type_s_fit_eq_plus"{
                        //detectionString = detectionString + "type_s_fit_eq_plus \n"
                        self.findData["type_s_fit_eq_plus"] = FindItem(title: "S Fit EQ + 등급", rect: objectBounds)
                    }
                    else if item.identifier == "type_s_fit_eq"{
                        //detectionString = detectionString + "type_s_fit_eq \n"
                        self.findData["type_s_fit_eq"] = FindItem(title: "S Fit EQ 등급", rect: objectBounds)
                    }
                    else if item.identifier == "mark_oil_e"{
                        //detectionString = detectionString + "rate_oil_e \n"
                        self.findData["mark_oil_e"] = FindItem(title: "오일 사용 E 등급", rect: objectBounds)
                    }
                    else if item.identifier == "mark_rain_e"{
                        //detectionString = detectionString + "mark_rain_e \n"
                        self.findData["mark_rain_e"] = FindItem(title: "빗길 미끄러짐 E 등급", rect: objectBounds)
                    }
                    else if item.identifier == "model_LK01"{
                        //detectionString = detectionString + "model_LK01 \n"
                        self.findData["model_LK01"] = FindItem(title: "라벨 LK01", rect: objectBounds)
                    }
                    else if item.identifier == "warning_message"{
                        //detectionString = detectionString + "warning_message \n"
                        self.findData["warning_message"] = FindItem(title: "경고문구 있음", rect: objectBounds)
                    }
                    else{
                    }
                    
                }
            }
            
            DispatchQueue.main.async {
                detectionString = ""
                                
                print("Found a \(detectionString)")
                self.findLabel.text = detectionString
                
                self.isHold = false
            }
        }
//            guard let topResult = results.first else {
//                print("unexpected result type from VNCoreMLRequest")
//                return
//            }
//
//            print(topResult.identifier, topResult.confidence)
        
        request.imageCropAndScaleOption = .scaleFill // 이미지를 인식할 수 있도록 만들어 준다.
        self.isHold = true
        
//        if let cgImage = UIImage(named: "4")?.cgImage {
//
//            let handler = VNImageRequestHandler(cgImage: cgImage)
//            DispatchQueue.global(qos: .userInteractive).async {
//              do {
//                try handler.perform([request])
//              } catch {
//                print(error)
//              }
//            }
//        }
        
        
        
        
        
//        let request = VNCoreMLRequest(model: model) { (vnRequest, error) in
//            if error != nil {
//                return
//            }
//
//            guard let results = vnRequest.results as? [VNClassificationObservation] else {
//                return
//            }
//
//            guard let firstObservation = results.first else {
//                return
//            }
//
//            if firstObservation.identifier.contains("banana") || firstObservation.identifier.contains("pineapple") {
//                print(firstObservation.identifier, firstObservation.confidence)
//
//                DispatchQueue.main.async {
//                    self.findLabel.text = firstObservation.identifier
//                }
//            }
//        }
        
        
        animalRecognitionWorkQueue.async {
            
        //    if let toCIImage = CIImage(cvImageBuffer: pixelBuffer) as! CIImage {
//            let toUIImage = UIImage(cgImage: toCIImage as! CGImage)
//            let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
//            let image = UIImage(ciImage: cameraImage)

            // 1104,828
            //print("toUIImage.size = \(image.size.width),  \(image.size.height)")
//            DispatchQueue.main.async {
//            self.imageVieww.image = image
//            }
            
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try requestHandler.perform([request])
            } catch {
                print(error)
            }
        }
        
        // try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])

    }
    
    
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect, index: Int) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "\(index)"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
}
