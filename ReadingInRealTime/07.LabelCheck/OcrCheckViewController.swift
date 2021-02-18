//
//  OcrCheckViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/18.
//

import UIKit

class OcrCheckViewController: UIViewController {
    
    @IBOutlet weak var previewView: HKPreviewView!
    @IBOutlet weak var cutoutView: UIView!
    
    @IBOutlet weak var guideLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var previewButton: UIButton!
    
    var mom: MLocrManager = MLocrManager()
    
    // 선택 데이터
    var selectCode: String = ""
    var totalNumber: Int = 0
    var checkNumber: Int = 0
    var isAllCheck: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "라벨 검증"
        
        // 세로모드 고정.
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        
        mom.setupCamera(preview: previewView, coutview: cutoutView, delegate: self)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        
        previewButton.setTitle("일시정시", for: .normal)
        previewButton.backgroundColor = .gray
        previewButton.setTitleColor(.white, for: .normal)
        self.previewButton.isHidden = false
            
        checkTextCalculation()
    }
    
    deinit {
        print("OcrCheckViewController deinit")
        BarcodeData.shared.defaltDataAll()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 화면구성
        mom.updateCutout()
    }
    
    func checkTextCalculation() {
        
        if selectCode == BarcodeData.shared.CODE_TITLE_240664 {
            totalNumber = BarcodeData.shared.CODE_DATA_240664.count
        } else if selectCode == BarcodeData.shared.CODE_TITLE_504056 {
            totalNumber = BarcodeData.shared.CODE_DATA_504056.count
        }
        
        guideLabel.text = "전체: \(totalNumber),  완료: \(checkNumber)"
        self.guideLabel.textColor = .black
    }
    
    @IBAction func actionButton(_ sender: Any) {
        if self.isAllCheck {
            return
        }
        
        if mom.toggleRunning() {
            previewButton.setTitle("일시정시", for: .normal)
            previewButton.backgroundColor = .gray
            previewButton.setTitleColor(.white, for: .normal)
        } else {
            previewButton.setTitle("다시시작", for: .normal)
            previewButton.backgroundColor = .orange
            previewButton.setTitleColor(.white, for: .normal)
        }
    }
    
}

extension OcrCheckViewController: MLocrManagerDelegate {
    func stringFound(array: [String]) {
        print("검출 개수 : \(array.count)")
        
        var isReloadData: Bool = false
        
        // 찾는지 확인
        if selectCode == BarcodeData.shared.CODE_TITLE_240664 {
            var checkCount: Int = 0
            BarcodeData.shared.CODE_DATA_240664.forEach { (tireData) in
                array.forEach { text in
                    if text.lowercased().contains(tireData.title.lowercased()) && tireData.check == 0 {
                        tireData.check = 1
                        isReloadData = true
                    }
                }
                
                if tireData.check  > 0 {
                    checkCount += 1
                }
            }
            
            self.checkNumber = checkCount
            if checkCount == BarcodeData.shared.CODE_DATA_240664.count {
                // 모두 체크 완료
                mom.stopRunning()
                isAllCheck = true
            }
        } else if selectCode == BarcodeData.shared.CODE_TITLE_504056 {
            var checkCount: Int = 0
            BarcodeData.shared.CODE_DATA_504056.forEach { (tireData) in
                array.forEach { text in
                    print("비교 \(tireData.title.lowercased()) == \(text.lowercased())")
                    if (text.lowercased().contains(tireData.title.lowercased()) ||
                        text.lowercased().contains(tireData.title2.lowercased()) )
                        && tireData.check == 0 {
                        tireData.check = 1
                        isReloadData = true
                    }
                }
                
                if tireData.check > 0 {
                    checkCount += 1
                }
            }
            
            self.checkNumber = checkCount
            if checkCount == BarcodeData.shared.CODE_DATA_504056.count {
                // 모두 체크 완료
                mom.stopRunning()
                isAllCheck = true
            }
        }
        
        // 결과
        DispatchQueue.main.async {
            if isReloadData {
                if self.isAllCheck {
                    self.guideLabel.text = "전체 \(self.totalNumber)개 확인 완료"
                    self.guideLabel.textColor = .red
                    
                    self.previewButton.isHidden = true
                } else {
                    self.guideLabel.text = "전체: \(self.totalNumber),  완료: \(self.checkNumber)"
                    self.guideLabel.textColor = .black
                }
                self.tableView.reloadData()
            }
        }
    }
    
}


extension OcrCheckViewController: UITableViewDelegate, UITableViewDataSource {
    
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
            let item = BarcodeData.shared.CODE_DATA_240664[indexPath.row]
            cell.textLabel?.text = item.title
            if item.check == 1 {
                cell.backgroundColor = .green
            } else if item.check == 2 {
                cell.backgroundColor = .lightGray
            } else {
                cell.backgroundColor = .white
            }
        } else if selectCode == BarcodeData.shared.CODE_TITLE_504056 {
            let item = BarcodeData.shared.CODE_DATA_504056[indexPath.row]
            cell.textLabel?.text = item.title
            if item.check == 1 {
                cell.backgroundColor = .green
            } else if item.check == 2 {
                cell.backgroundColor = .lightGray
            } else {
                cell.backgroundColor = .white
            }
        }
        cell.selectionStyle = .none
        
        return cell
    }
    
}

