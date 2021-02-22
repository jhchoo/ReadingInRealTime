//
//  CardRecognizeTextManager.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/22.
//

import Foundation
import UIKit
import Vision

class CardRecognizeTextManager {
    
    typealias RecognizeTextCompletion = (([String]) -> Void)
    private var completionWithHandler: RecognizeTextCompletion?
    
    private var ocrRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    init() {
        configureOCR()
    }
    
    private func configureOCR() {
        ocrRequest = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                if let completion = self?.completionWithHandler {
                    completion([])
                }
                return
            }
            
            var sendArray:[String] = []
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else {
                    if let completion = self?.completionWithHandler {
                        completion([])
                    }
                    return
                }
                sendArray.append(topCandidate.string)
            }
            
            DispatchQueue.main.async {
                // 데이터 전달
                if let completion = self?.completionWithHandler {
                    completion(sendArray)
                }
            }
        }
        
        ocrRequest.recognitionLevel = .accurate
        // ["en-US", "fr-FR", "it-IT", "de-DE", "es-ES", "pt-BR", "zh-Hans", "zh-Hant"]
        // ["영어", "프랑스어", "이탈리아어", "독일어", "스페인", "포르투칼-브라질어", "중국어간체", "중국어번체"] // 7개국어
        ocrRequest.recognitionLanguages = ["en-US"]
        ocrRequest.usesLanguageCorrection = true
    }
    
    func processImage(_ image: UIImage, completion: @escaping RecognizeTextCompletion) {
        completionWithHandler = completion
        
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try requestHandler.perform([self.ocrRequest])
        } catch {
            completion([])
            print(error)
        }
    }
    
}
