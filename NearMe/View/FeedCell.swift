//
//  FeedCell.swift
//  NearMe
//
//  Created by Mandy Chen on 10/11/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit

class FeedCell: UITableViewCell {

    @IBOutlet weak var cellView: UIView!
    @IBOutlet weak var feedContentView: UIView!
    @IBOutlet weak var feedImageView: UIImageView!
    @IBOutlet weak var feedLabel: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var likeCountLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    
    let DEFAULT_SCREEN_NAME = "Ninja"
    var post: Post! {
        didSet{
            
            if let imageUrlStr = post.imageUrl, let imageUrl = URL(string: imageUrlStr), let data = NSData(contentsOf: imageUrl) {
                    feedImageView.image = UIImage(data: data as Data)
            } else {
                feedImageView.isHidden = true
            }
            feedLabel.text = post.message
            
            if let createTime = post.creationTimestamp {
                 timestamp.text = FeedCell.convertEpochTimeStamp(timestamp: createTime)
            }

            likeCountLabel.text = "\(post.likes ?? 0)"
            
            avatarView.image = UIImage(named: "user1")
            avatarView.clipsToBounds = true
            avatarView.layer.cornerRadius = 30
            avatarView.layer.borderWidth = 0.5
            avatarView.layer.borderColor = cellView.backgroundColor?.cgColor
            
            screenNameLabel.text = post.screen_name ?? DEFAULT_SCREEN_NAME
            if let distance = post.distance {
                distanceLabel.text = distance
            } else {
                distanceLabel.isHidden = true
            }
            
            if let place = post.place {
                placeLabel.text = place
            }
            
            let likeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
            likeImage.isUserInteractionEnabled = true
            likeImage.addGestureRecognizer(likeTapGestureRecognizer)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        cellView.clipsToBounds = true
        cellView.layer.cornerRadius = 5
    
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
        print("tapped")
        //TODO: send api call for like/unlike
        if tappedImage.image == UIImage(named: "like") {
            print("is like")
        } else if tappedImage.image == UIImage(named: "liked") {
            print("is liked")
        }
        
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
