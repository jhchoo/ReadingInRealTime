//
//  BarcodeData.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/18.
//

import Foundation

class TireData {
    var check: Int = 0
    var title: String = ""
    var title2: String = ""
    
    init(check: Int, title: String) {
        self.check = check
        self.title = title
        self.title2 = ""
    }
    
    init(check: Int, title: String, title2: String) {
        self.check = check
        self.title = title
        self.title2 = title2
    }
}

class BarcodeData: NSObject {
    static let shared = BarcodeData()
    
    let CODE_TITLE_240664 = "1005392"
    var CODE_DATA_240664:[TireData] = [ TireData(check: 0, title: "1005392"),
                                        TireData(check: 0, title: "225/75R16 104H"),
                                        TireData(check: 0, title: "RA23"),
                                        TireData(check: 0, title: "70 dB")]
    
    let CODE_TITLE_504056 = "1026584"
    var CODE_DATA_504056:[TireData] = [ TireData(check: 0, title: "1026584"),
                                        TireData(check: 0, title: "215/50ZR17 95W XL"),
                                        TireData(check: 0, title: "LK01"),
                                        TireData(check: 0, title: "S FIT EQ+", title2: "S FIT EQ +"),
                                        TireData(check: 0, title: "WARNING")]
    
    func defaltDataAll() {
        CODE_DATA_240664.forEach { (tireData) in
            tireData.check = 0
        }
        CODE_DATA_504056.forEach { (tireData) in
            tireData.check = 0
        }
    }
}
