//
//  CardTesseractManager.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/22.
//

import Foundation
import UIKit

// 모바일용 라이브러리 제공
// Tesseract 4의 LSTM OCR 엔진  (Long Short-Term Memory 알고리즘)
// https://github.com/SwiftyTesseract/libtesseract

// 엔진 사용법 제공
// https://github.com/SwiftyTesseract/SwiftyTesseract

// 언어별 데이터 제공
// 이 모델은 Tesseract 4의 LSTM OCR 엔진에서만 작동합니다.  (Long Short-Term Memory 알고리즘)
// https://github.com/tesseract-ocr/tessdata_best
// https://github.com/tesseract-ocr/tessdata_best/tree/4.1.0 // 사용 버전


class CardTesseractManager {
    
    typealias RecognizeTextCompletion = ((String) -> Void)
    private var completionWithHandler: RecognizeTextCompletion?
    
    var tesseract: SwiftyTesseract!
    
    init() {
        configureOCR()
    }
    
    private func configureOCR() {
        tesseract = SwiftyTesseract(languages: [.korean, .english])
        tesseract.minimumCharacterHeight = 3
    }
    
    func processImage(_ image: UIImage, completion: @escaping RecognizeTextCompletion) {
        completionWithHandler = completion
        
        tesseract.performOCR(on: image) { (recognizedText) in
            if let recognizedText = recognizedText {
                completion(recognizedText)
            }
        }
    }
    
}
