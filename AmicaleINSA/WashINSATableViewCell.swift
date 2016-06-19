//
//  WashINSATableViewCell.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 27/03/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit

class WashINSATableViewCell: UITableViewCell {
    
    @IBOutlet weak var numberMachineLabel: UILabel!
    @IBOutlet weak var typeMachineLabel: UILabel!
    @IBOutlet weak var availabilityMachineLabel: UILabel!
    @IBOutlet weak var availableInTimeMachineLabel: UILabel!
    @IBOutlet weak var startEndTimeLabel: UILabel!
    @IBOutlet weak var reservedMachineCircularLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
