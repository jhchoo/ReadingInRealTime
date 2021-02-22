//
//  CardData.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/22.
//

import Foundation

class CardData {
    // 인식된 텍스트 블록에서 텍스트 추출
    enum SampleType: Int {
        case apple = 0
        case tesseract
    }
    
    var type: SampleType = .apple
    var title: String = ""
    var desc: String = ""
    
    init(_ type: SampleType, title: String, desc: String) {
        self.type = type
        self.title = title
        self.desc = desc
    }
}
