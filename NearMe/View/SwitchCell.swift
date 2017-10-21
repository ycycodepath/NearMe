//
//  SwitchCell.swift
//  NearMe
//
//  Created by Xiang Yu on 10/17/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit

@objc protocol SwitchCellDelegate {
    @objc optional func switchCell(switchCell: SwitchCell, didChangeValue value: Bool)
}

class SwitchCell: UITableViewCell {
    
    @IBOutlet weak var switchLabel: UILabel!
    @IBOutlet weak var onSwitch: UISwitch!
    
    weak var delegate: SwitchCellDelegate!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        onSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // disable selection effect
        selectionStyle = .none
    }
    
    @objc func switchValueChanged() {
        print("switch value changed")
        delegate?.switchCell?(switchCell: self, didChangeValue: onSwitch.isOn)
    }
    
}
