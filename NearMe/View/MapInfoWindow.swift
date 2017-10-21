//
//  mapInfoWindow.swift
//  NearMe
//
//  Created by Mandy Chen on 10/20/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit

class MapInfoWindow: UIView {
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet var contentView: UIView!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    func initSubviews(){
        let nib = UINib(nibName: "MapInfoWindow", bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
    }
    
    var screenName: String? {
        get { return screenNameLabel?.text }
        set { screenNameLabel.text = newValue }
    }
    
    var message: String? {
        get { return messageLabel?.text }
        set { messageLabel.text = newValue }
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
