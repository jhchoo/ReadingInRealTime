//
//  HomeViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/15.
//

import UIKit

// swift text recognition

//case ocrTesseract // 오픈소스, 등록언어에 따라, 한글, 영문 가능
//case ocrApple // 애플에서 만든  영문만 가능
//case ocrGoogle // 이미지를 서버에 전송, 한글, 영문 가능, 통신필요 - 1000건 이상 유료
//case ocrKakao // 이미지를 서버에 전송, 한글,영문 가능, 통신필요

// 인식된 텍스트 블록에서 텍스트 추출
enum SampleType: Int {
    case barcode = 0
    case businessCard
    case realTime_OCR_Apple
    case realTime_OCR_Google
    case realTime_ML_Apple
    case realTime_ML_Google
    case realTime_test
    
    var vo: (Int, String) {
        switch self {
        case .barcode:              return (0, "바코드 인식 Apple")
        case .businessCard:         return (1, "명함인식 OCR")
        case .realTime_OCR_Apple:   return (2, "실시간 글자인식 Apple")
        case .realTime_OCR_Google:  return (3, "실시간 글자인식 Google")
        case .realTime_ML_Apple:    return (4, "실시간 머신러닝 Apple")
        case .realTime_ML_Google:   return (5, "실시간 머신러닝 Google")
        case .realTime_test:        return (6, "바코드-글자인식-머신러닝")
        }
    }
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
        
        switch indexPath.row {
        case SampleType.barcode.rawValue:
            cell.textLabel?.text = SampleType.barcode.vo.1
        case SampleType.businessCard.rawValue:
            cell.textLabel?.text = SampleType.businessCard.vo.1
        case SampleType.realTime_OCR_Apple.rawValue:
            cell.textLabel?.text = SampleType.realTime_OCR_Apple.vo.1
        case SampleType.realTime_OCR_Google.rawValue:
            cell.textLabel?.text = SampleType.realTime_OCR_Google.vo.1
        case SampleType.realTime_ML_Apple.rawValue:
            cell.textLabel?.text = SampleType.realTime_ML_Apple.vo.1
        case SampleType.realTime_ML_Google.rawValue:
            cell.textLabel?.text = SampleType.realTime_ML_Google.vo.1
        case SampleType.realTime_test.rawValue:
            cell.textLabel?.text = SampleType.realTime_test.vo.1
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
                
        switch indexPath.row {
        case SampleType.barcode.rawValue:
            let stroyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = stroyboard.instantiateViewController(withIdentifier: "ScannerVC") as? ScannerViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case SampleType.businessCard.rawValue:
            print("11")
        case SampleType.realTime_OCR_Apple.rawValue:
            print("11")
        case SampleType.realTime_OCR_Google.rawValue:
            print("11")
        case SampleType.realTime_ML_Apple.rawValue:
            print("11")
        case SampleType.realTime_ML_Google.rawValue:
            print("11")
        case SampleType.realTime_test.rawValue:
            print("11")
        default:
            break
        }
    }
    
}
