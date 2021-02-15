//
//  PreviewView.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/15.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    
    // 전통적인 카메라의 뷰파인더 처럼,
    // 사진을 찍거나 영상을 녹화하기 전에 사용자가 카메라의 입력을 볼 수 있는 것은 매우 중요하다.
    // 우리는 이같은 preview를 AVCaptureVideoPreviewLayer를 capture session에 연결함으로써 제공할 수 있다.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
