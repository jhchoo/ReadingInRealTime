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
    case stt_Apple
    
    var tuple: (String, String) {
        switch self {
        case .barcode:              return ("barcode", "바코드&QR Apple")
        case .businessCard:         return ("card", "명함인식 OCR")
        case .realTime_OCR_Apple:   return ("apple", "실시간 글자인식 Apple")
        case .realTime_OCR_Google:  return ("google", "실시간 글자인식 Google")
        case .realTime_ML_Apple:    return ("apple", "이미지 오브젝트 머신러닝 Apple")
        case .realTime_ML_Google:   return ("google", "이미지 오브젝트 머신러닝 Google")
        case .realTime_test:        return ("han", "상품번호인식 -> 글자인식 샘플")
        case .stt_Apple:            return ("apple", "STT Apple 사용")
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
        tabelView.tableFooterView = UIView()
    }

}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var tuple: (String, String) = ("", "")
        
        switch indexPath.row {
        case SampleType.barcode.rawValue:
            tuple = SampleType.barcode.tuple
            cell.accessoryType = .disclosureIndicator
        case SampleType.businessCard.rawValue:
            tuple = SampleType.businessCard.tuple
            cell.accessoryType = .disclosureIndicator
        case SampleType.realTime_OCR_Apple.rawValue:
            tuple = SampleType.realTime_OCR_Apple.tuple
            cell.accessoryType = .disclosureIndicator
        case SampleType.realTime_OCR_Google.rawValue:
            tuple = SampleType.realTime_OCR_Google.tuple
        case SampleType.realTime_ML_Apple.rawValue:
            tuple = SampleType.realTime_ML_Apple.tuple
            cell.accessoryType = .disclosureIndicator
        case SampleType.realTime_ML_Google.rawValue:
            tuple = SampleType.realTime_ML_Google.tuple
        case SampleType.realTime_test.rawValue:
            tuple = SampleType.realTime_test.tuple
            cell.accessoryType = .disclosureIndicator
        case SampleType.stt_Apple.rawValue:
            tuple = SampleType.stt_Apple.tuple
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        
        cell.imageView?.image = UIImage(named: tuple.0)
        cell.textLabel?.text = tuple.1
        
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
            let stroyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = stroyboard.instantiateViewController(withIdentifier: "CardVC") as? CardViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case SampleType.realTime_OCR_Apple.rawValue:
            let stroyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = stroyboard.instantiateViewController(withIdentifier: "VisionVC") as? VisionViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case SampleType.realTime_OCR_Google.rawValue:
            print("11")
        case SampleType.realTime_ML_Apple.rawValue:
            let stroyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = stroyboard.instantiateViewController(withIdentifier: "AppleMachineVC") as? AppleMachineViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case SampleType.realTime_ML_Google.rawValue:
            print("22")
        case SampleType.realTime_test.rawValue:
            let stroyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = stroyboard.instantiateViewController(withIdentifier: "LabelCheckVC") as? LabelCheckViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        case SampleType.stt_Apple.rawValue:
            let stroyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = stroyboard.instantiateViewController(withIdentifier: "SttVC") as? SttViewController {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        default:
            break
        }
    }
    
}
