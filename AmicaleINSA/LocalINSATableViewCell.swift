//
//  LocalINSATableViewCell.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 20/05/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit

class LocalINSATableViewCell: UITableViewCell {

    @IBOutlet weak var availabilityLocalLabel: UILabel!
    @IBOutlet weak var nameLocalLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
