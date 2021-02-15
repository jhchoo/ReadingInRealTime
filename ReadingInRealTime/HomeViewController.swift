//
//  HomeViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/15.
//

import UIKit

// swift text recognition

//case ocrTesseract // 한글, 영문 가능
//case ocrApple // 영문만 가능
//case ocrGoogle // 한글, 영문 가능, 통신필요
//case ocrKakao // 한글,영문 가능, 통신필요

enum SampleType: String {
    case barcode = "바코드 인식 Apple"
    case businessCard = "명함인식 OCR"
    case realTime_OCR_Apple = "실시간 글자인식 Apple" // 영문
    case realTime_OCR_Google = "실시간 글자인식 Google" // 영문
    case realTime_ML_Apple = "실시간 머신러닝 Apple"
    case realTime_ML_Google = "실시간 머신러닝 Google"
    case realTime_test = "바코드-글자인식-머신러닝"
}

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tabelView: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        tabelView.delegate = self
        tabelView.dataSource = self
        tabelView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = SampleType.barcode.rawValue
        } else if indexPath.row == 1 {
            cell.textLabel?.text = SampleType.businessCard.rawValue
        } else if indexPath.row == 2 {
            cell.textLabel?.text = SampleType.realTime_OCR_Apple.rawValue
        } else if indexPath.row == 3 {
            cell.textLabel?.text = SampleType.realTime_OCR_Google.rawValue
        } else if indexPath.row == 4 {
            cell.textLabel?.text = SampleType.realTime_ML_Apple.rawValue
        } else if indexPath.row == 5 {
            cell.textLabel?.text = SampleType.realTime_ML_Google.rawValue
        } else if indexPath.row == 6 {
            cell.textLabel?.text = SampleType.realTime_test.rawValue
        } else {
            cell.textLabel?.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        
    }
    
}
