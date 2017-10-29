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
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    
    @IBOutlet weak var avatarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postImageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var postImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var likeButton: UIButton!
    
    private var postImgAspect: CGFloat = 0
    var totalHeightConstraint: CGFloat = 0
    var handleLikeButtonClicked: (Post) -> Void = { (post) -> Void in }
    
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
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.layer.borderWidth = 0.5
    
        postImageView.clipsToBounds = true
        postImageView.layer.cornerRadius = 8
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 10
        contentView.frame = bounds
        addSubview(contentView)
        
        totalHeightConstraint = avatarTopConstraint.constant + avatarHeightConstraint.constant + postImageTopConstraint.constant + messageLabelTopConstraint.constant + messageLabelBottomConstraint.constant
        
        likeButton.setImage(UIImage(named: "homeliked"), for: .selected)
        likeButton.setImage(UIImage(named: "homelike"), for: .normal)
    }
    
    var screenName: String? {
        get { return screenNameLabel?.text }
        set { screenNameLabel.text = newValue }
    }
    
    var message: String? {
        get { return messageLabel?.text }
        set {
            messageLabel.text = newValue
            messageLabel.sizeToFit()
        }
    }
    
    var likeCount: String? {
        get { return likeCountLabel?.text }
        set { likeCountLabel.text = newValue }
    }
    
    var timeStamp: String? {
        get { return timeStampLabel?.text }
        set { timeStampLabel.text = newValue }
    }
    
    var avatar: UIImage? {
        get { return avatarImageView?.image }
        set { avatarImageView.image = newValue }
    }
    
    var postImage: UIImage? {
        get { return postImageView?.image }
        set {
            postImageView.image = newValue
            postImgAspect = CGFloat((newValue?.size.height)! / (newValue?.size.width)!)
            postImageHeightConstraint.constant = postImageView.frame.size.width * postImgAspect
        }
    }
    
    var post: Post! {
        didSet{
            screenName = post.screen_name
            message = post.message
            likeCount = "\(post.likes ?? 0)"
            if let createTime = post.creationTimestamp {
                timeStamp = FeedCell.convertEpochTimeStamp(timestamp: createTime)
            }
            
            if let avatarPath = post.avatarUrl {
                let imagePath = Bundle.main.resourcePath! + avatarPath
                avatar = UIImage(contentsOfFile: imagePath) ?? UIImage(named: "user1")
            } else {
                avatar = UIImage(named: "user1")
            }
            
            
            if let imageUrlStr = post.imageUrl, let imageUrl = URL(string: imageUrlStr), let data = try? Data(contentsOf: imageUrl) {
                postImage =  UIImage(data: data)
            } else {
                postImageHeightConstraint.constant = 0
            }
            
            if LikeService.sharedInstance.isPostLiked(postId: post.id ?? "") {
                likeButton.isSelected = true
            } else {
                likeButton.isSelected = false
            }
            
        }
    }
    
    @IBAction func onLikeButtonClicked(_ sender: Any) {
        print("mapinfowindow: onLikeButtonClicked")
        
        self.likeButton.isSelected = !self.likeButton.isSelected
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
