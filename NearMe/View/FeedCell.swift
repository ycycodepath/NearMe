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
import Lottie

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
    @IBOutlet weak var fireImageView: UIImageView!
    
    let DEFAULT_SCREEN_NAME = "Ninja"
    let screenSize: CGRect = UIScreen.main.bounds
    
    var handleFeedImageTapped: (UIImageView, Post) -> Void = { (imageView, post) -> Void in }
    var handleLikeButtonClicked: (Post) -> Void = { (post) -> Void in }
    
    var post: Post! {
        didSet{
            if let imageUrlStr = post.imageUrl, let imageUrl = URL(string: imageUrlStr) {
                feedImageView.image = nil
                feedImageView.setImageWith(imageUrl)
                feedImageView.isHidden = false
                
                imageHeightConstraint.constant = self.frame.size.width
                self.contentView.layoutIfNeeded()
                
            } else {
                feedImageView.isHidden = true
                imageHeightConstraint.constant = 0
                feedImageView.image = nil
                self.contentView.layoutIfNeeded()
            }
            feedLabel.text = post.message
            
            if let createTime = post.creationTimestamp {
                 timestamp.text = FeedCell.convertEpochTimeStamp(timestamp: createTime)
            }

            if LikeService.sharedInstance.isPostLiked(postId: post.id ?? "") {
                likeButton.isSelected = true
            } else {
                likeButton.isSelected = false
            }
            
            likeCountLabel.text = "\(post.likes ?? 0)"
            if post.likes != nil && post.likes! >= 500 {
                fireImageView.isHidden = false
            } else {
                fireImageView.isHidden = true
            }
            
            if let avatarPath = post.avatarUrl {
                let imagePath = Bundle.main.resourcePath! + avatarPath
                avatarView.image = UIImage(contentsOfFile: imagePath) ?? UIImage(named: "user1")
            } else {
                avatarView.image = UIImage(named: "user1")
            }
            
            screenNameLabel.text = post.screen_name ?? DEFAULT_SCREEN_NAME
            if let distancestr = post.distance, let distance = Double(distancestr) {
                let distance = String(format: "%.2f mi", Settings.milesPerKM * distance)
                
                distanceLabel.text = distance
            } else {
                distanceLabel.text = ""
            }
            
            if let place = post.place {
                placeLabel.text = place
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = avatarView.frame.height / 2
        avatarView.layer.borderColor = UIColor(white: 0.7, alpha: 0.8).cgColor
        avatarView.layer.borderWidth = 1

        
        let feedImgTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(feedImageTapped(tapGestureRecognizer:)))
        feedImageView.isUserInteractionEnabled = true
        feedImageView.addGestureRecognizer(feedImgTapGestureRecognizer)

        
        likeButton.setImage(UIImage(named: "homeliked"), for: .selected)
        likeButton.setImage(UIImage(named: "homelike"), for: .normal)

        let doubleTapToLike = UITapGestureRecognizer(target: self, action:  #selector(handleDoubleTapToLike))
        doubleTapToLike.numberOfTapsRequired = 2;
        self.contentView.addGestureRecognizer(doubleTapToLike)
        
    }
    
    @IBAction func onLikeButtonClicked(_ sender: Any) {
        
        //toggle
        self.likeButton.isSelected = !self.likeButton.isSelected
        animateLiked()
        handleLikeButtonClicked(post)
        
    }

    @objc func handleDoubleTapToLike() {
        self.likeButton.isSelected = !self.likeButton.isSelected
        animateLiked()
        handleLikeButtonClicked(post)
    }
    
    func animateLiked() {
        if self.likeButton.isSelected {
            let animationView = LOTAnimationView(name: "like")
            animationView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            animationView.center = CGPoint(x: self.likeButton.frame.size.width/2, y: self.likeButton.frame.size.height/2)
            animationView.contentMode = .scaleAspectFill
            animationView.loopAnimation = false
            self.likeButton.addSubview(animationView)
            
            animationView.play(completion: { (completed) in
                animationView.removeFromSuperview()
            })
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func feedImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImageView = tapGestureRecognizer.view as! UIImageView
        handleFeedImageTapped(tappedImageView, post)
    }
    
    
    static func convertEpochTimeStamp(timestamp: Double) -> String {
        let creationTime = timestamp / 1000
        let creationDate = Date(timeIntervalSince1970: creationTime)
        let interval = Date().offsetFrom(date: creationDate)
        return interval.isEmpty ? "Just Now" : interval
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
