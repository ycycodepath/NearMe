//
//  FeedCell.swift
//  NearMe
//
//  Created by Mandy Chen on 10/11/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit
import AFNetworking
import IDMPhotoBrowser

class FeedCell: UITableViewCell {

    @IBOutlet weak var feedImageView: UIImageView!
    @IBOutlet weak var feedLabel: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var likeButton: UIButton!
    
    let DEFAULT_SCREEN_NAME = "Ninja"
    let screenSize: CGRect = UIScreen.main.bounds
    
    var handleFeedImageTapped: (UIImageView, Post) -> Void = { (imageView, post) -> Void in }
    var handleLikeButtonClicked: (Post) -> Void = { (post) -> Void in }
    
    var post: Post! {
        didSet{
            if let imageUrlStr = post.imageUrl, let imageUrl = URL(string: imageUrlStr) {
                feedImageView.setImageWith(imageUrl)
                feedImageView.isHidden = false
                
                imageHeightConstraint.constant = 182
//                feedImageView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height * 0.5)
                self.contentView.layoutIfNeeded()
            } else {
                print("no feedImageView")
                feedImageView.isHidden = true
                imageHeightConstraint.constant = 0
                feedImageView.image = nil
                self.contentView.layoutIfNeeded()
            }
            feedLabel.text = post.message
            
            if let createTime = post.creationTimestamp {
                 timestamp.text = FeedCell.convertEpochTimeStamp(timestamp: createTime)
            }

            
            if LikeService.sharedInstance.isPostLiked(postId: post.id!) {
                likeButton.isSelected = true
            }
            
            likeCountLabel.text = "\(post.likes ?? 0)"
            
            avatarView.image = UIImage(named: "user1")
            avatarView.clipsToBounds = true
            avatarView.layer.cornerRadius = 30
            avatarView.layer.borderWidth = 0.5

            
            screenNameLabel.text = post.screen_name ?? DEFAULT_SCREEN_NAME
            if let distance = post.distance {
                distanceLabel.text = distance
            } else {
                distanceLabel.isHidden = true
            }
            
            if let place = post.place {
                placeLabel.text = place
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let feedImgTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(feedImageTapped(tapGestureRecognizer:)))
        feedImageView.isUserInteractionEnabled = true
        feedImageView.addGestureRecognizer(feedImgTapGestureRecognizer)

        
        likeButton.setImage(UIImage(named: "liked"), for: .selected)
        likeButton.setImage(UIImage(named: "like"), for: .normal)

    }
    
    @IBAction func onLikeButtonClicked(_ sender: Any) {
        
        //toggle
        self.likeButton.isSelected = !self.likeButton.isSelected
        handleLikeButtonClicked(post)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func feedImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImageView = tapGestureRecognizer.view as! UIImageView
//        let image = tappedImageView.image!
        handleFeedImageTapped(tappedImageView, post)
    }
    
    
    static func convertEpochTimeStamp(timestamp: Double) -> String {
        let creationTime = timestamp / 1000
        let creationDate = Date(timeIntervalSince1970: creationTime)
        let interval = Date().offsetFrom(date: creationDate)
        return interval
    }
}

extension Date {
    
    func offsetFrom(date: Date) -> String {
        
        let dayHourMinuteSecond: Set<Calendar.Component> = [.day, .hour, .minute, .second]
        let difference = NSCalendar.current.dateComponents(dayHourMinuteSecond, from: date, to: self);
        
        let minutes = "\(difference.minute ?? 0)m"
        let hours = "\(difference.hour ?? 0)h" + " " + minutes
        let days = "\(difference.day ?? 0)d" + " " + hours
        print("days : \(days)")
        if let day = difference.day, day > 0 { return days }
        if let hour = difference.hour, hour > 0 { return hours }
        if let minute = difference.minute, minute > 0 { return minutes }
        return ""
    }
    
}

