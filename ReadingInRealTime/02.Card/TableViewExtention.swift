//
//  TableViewExtention.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/22.
//

import Foundation
import UIKit

extension UITableView {

    func setEmptyMessage(_ message: String) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        messageLabel.sizeToFit()
        view.addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: view.topAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
            ])
        
        self.backgroundView = view
        self.backgroundView?.backgroundColor = UIColor.clear
        self.separatorStyle = .none
    }
    
    func emptyHidden(_ count: Int = 0) {
        if count == 0 {
            self.backgroundView?.isHidden = false
        } else {
            self.backgroundView?.isHidden = true
        }
    }
}
