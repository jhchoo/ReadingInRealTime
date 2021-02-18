//
//  LabelCheckViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/17.
//

import UIKit

class LabelCheckViewController: UIViewController {

    @IBOutlet weak var cameraView: HKPreviewView!
    @IBOutlet weak var cutoutView: UIView!
    
    @IBOutlet weak var guideLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var ocrButton: UIButton!
    
    // var bm: BarcodeManager = BarcodeManager()
    var mom: MLocrManager = MLocrManager()
    
    // 선택 데이터
    var selectCode: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "상품번호 인식"
        // 세로모드 고정.
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        
        // 캡쳐 시작
        // bm.setupCamera(preview: cameraView, coutview: cutoutView, delegate: self)
        mom.setupCamera(preview: cameraView, coutview: cutoutView, delegate: self)
                
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        
        defaultValueUpdate()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "재시도", style: .plain, target: self, action: #selector(refreshTapped))
    }
    
    deinit {
        print("LabelCheckViewController deinit")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 프리뷰 위치 조정
        //bm.updatePreview()
        //bm.updateCutout()
        mom.updateCutout()
    }
    
    @objc func refreshTapped() {
        // 재시도 버튼, 초기화 시킴
        // bm.startRunning()
        mom.startRunning()
        defaultValueUpdate()
        tableView.reloadData()
    }
    
    func defaultValueUpdate() {
        selectCode = ""
        self.guideLabel.text = "상품번호 찍고 정보를 확인"
        ocrButton.setTitle("상품 정보가 필요 합니다.", for: .normal)
        ocrButton.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        ocrButton.isEnabled = false
    }
    
    @IBAction func actionOcr(_ sender: Any) {
        // OCR 동작하러 간다.
        
        let stroyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = stroyboard.instantiateViewController(withIdentifier: "OcrCheckVC") as? OcrCheckViewController {
            vc.selectCode = self.selectCode
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension LabelCheckViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectCode == BarcodeData.shared.CODE_TITLE_240664 {
            return BarcodeData.shared.CODE_DATA_240664.count
        } else if selectCode == BarcodeData.shared.CODE_TITLE_504056 {
            return BarcodeData.shared.CODE_DATA_504056.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if selectCode == BarcodeData.shared.CODE_TITLE_240664 {
            cell.textLabel?.text = BarcodeData.shared.CODE_DATA_240664[indexPath.row].title
        } else if selectCode == BarcodeData.shared.CODE_TITLE_504056 {
            cell.textLabel?.text = BarcodeData.shared.CODE_DATA_504056[indexPath.row].title
        }
        cell.selectionStyle = .none
        
        return cell
    }
    
}

//extension LabelCheckViewController: BarcodeManagerDelegate {
//    func codeFound(code: String) {
//        print("code \(code)")
//
//        selectCode = code
//        tableView.reloadData()
//
//        var count: Int = 0
//        if selectCode == BarcodeData.shared.CODE_TITLE_240664 {
//            count = BarcodeData.shared.CODE_DATA_240664.count
//        } else if selectCode == BarcodeData.shared.CODE_TITLE_504056 {
//            count = BarcodeData.shared.CODE_DATA_504056.count
//        }
//
//        if selectCode == BarcodeData.shared.CODE_TITLE_240664 || selectCode == BarcodeData.shared.CODE_TITLE_504056 {
//            self.guideLabel.text = selectCode
//            ocrButton.setTitle("\(count)개 라벨검증 이동", for: .normal)
//            ocrButton.setTitleColor(.white, for: .normal)
//            ocrButton.backgroundColor = .orange
//            ocrButton.isEnabled = true
//        }
//    }
//}

extension LabelCheckViewController: MLocrManagerDelegate {
    func stringFound(array: [String]) {

        var findCond = ""
        for item in array {
            if item.count == 7 && item.isNumeric() {
                findCond = item
                break
            }
        }
        if findCond.count == 0 {
            return
        }
        
        selectCode = findCond
        
        var count: Int = 0
        if selectCode == BarcodeData.shared.CODE_TITLE_240664 {
            count = BarcodeData.shared.CODE_DATA_240664.count
        } else if selectCode == BarcodeData.shared.CODE_TITLE_504056 {
            count = BarcodeData.shared.CODE_DATA_504056.count
        }
        
        if count > 0 {
            
            mom.stopRunning()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.guideLabel.text = self.selectCode
                self.ocrButton.setTitle("\(count)개 라벨검증 이동", for: .normal)
                self.ocrButton.setTitleColor(.white, for: .normal)
                self.ocrButton.backgroundColor = .orange
                self.ocrButton.isEnabled = true
            }
        }
    }
    
}
