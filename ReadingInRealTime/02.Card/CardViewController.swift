//
//  CardViewController.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/22.
//

import UIKit
import VisionKit

class CardViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scanImage: UIImageView!
    
    var scanData: [CardData] = []
    
    // iOS 카드 메니저
    var crtm: CardRecognizeTextManager = CardRecognizeTextManager()
    var tesseractm: CardTesseractManager = CardTesseractManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "명함인식"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "CardTableViewCell", bundle: nil), forCellReuseIdentifier: "CardTableViewCell")
        tableView.tableFooterView = UIView()
        
        tableView.setEmptyMessage("상단의 버튼으로 명함을 촬영 하세요")
        
        // 우측 상단 버튼
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "명함촬영", style: .plain, target: self, action: #selector(rightTapped))
    }
    
    deinit {
        print("CardViewController deinit")
    }
    
    @objc func rightTapped() {
        let scanVC = VNDocumentCameraViewController()
        scanVC.delegate = self
        present(scanVC, animated: true)
    }
    
    // 이미지를 파싱한다.
    func processImageIos(_ image: UIImage) {
        
        crtm.processImage(image) { [weak self] (array) in

            var ocrText = ""
            for observation in array {
                ocrText += observation + "\n"
            }
            self?.scanData.append(CardData(.apple, title: "애플 인식언어 (en,fr,it,de,es,br,ch)", desc: ocrText))

            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    func processImageTesseract(_ image: UIImage) {
        
        tesseractm.processImage(image) { [weak self] (ocrText) in

            self?.scanData.append(CardData(.apple, title: "테서렉트 인식언어 (영어+한글)", desc: ocrText))

            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
}


extension CardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let dataCount: Int = scanData.count
        
        self.tableView.emptyHidden(dataCount)
        return dataCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CardTableViewCell", for: indexPath) as! CardTableViewCell
        
        cell.configure(indexPath.row, item: scanData[indexPath.row] )
        
        return cell
    }
    
}

extension CardViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        scanImage.image = scan.imageOfPage(at: 0)
        DispatchQueue.main.async {
            self.tableView.setEmptyMessage("로딩중")
            self.scanData.removeAll()
            self.tableView.reloadData()
        }
        
        controller.dismiss(animated: true) { [weak self] in
            if let img = self?.scanImage.image {
                self?.processImageIos(img)
                self?.processImageTesseract(img)
            }
        }
            
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print("Handle properly error")
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        print("Handle properly error")
        controller.dismiss(animated: true)
    }
}
