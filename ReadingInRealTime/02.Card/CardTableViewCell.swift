//
//  CardTableViewCell.swift
//  ReadingInRealTime
//
//  Created by jae hwan choo on 2021/02/22.
//

import UIKit

class CardTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(_ index: Int, item: CardData) {
        titleLabel.text = item.title
        descLabel.text = item.desc
    }
}
