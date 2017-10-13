//
//  ComposeViewController.swift
//  NearMe
//
//  Created by Xiang Yu on 10/10/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit
import ImagePicker
import GooglePlacePicker

//@objc protocol ComposeViewControllerDelegate {
//    @objc optional func composeViewController(_ composeViewController: ComposeViewController, didPost status: Post)
//}

class ComposeViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postTextView: UITextView!
    
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet var keyboardToolBar: UIToolbar!
    @IBOutlet weak var countBarButton: UIBarButtonItem!
    @IBOutlet weak var locationButton: UIButton!
    
    @IBOutlet weak var postImgViewHeightConstraint: NSLayoutConstraint!
    
    var postImageViewWidth: CGFloat!
    var placesClient: GMSPlacesClient!
    
    //weak var delegate: ComposeViewControllerDelegate!
    
    let postCharLimit = 140
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient.shared()
        getCurrentPlace()
        
        self.hideKeyboardWhenTappedAround()
//        screennameLabel.text = "@\(currentUser.screenname ?? "null")"
//        usernameLabel.text = currentUser.name
//        
//        if let imageURL = currentUser.profileImgUrl {
//            profileImgView.setImageWith(imageURL)
//        } else {
//            profileImgView.image = nil
//        }

        postTextView.delegate = self
        postTextView.becomeFirstResponder()
        
        postImageView.layer.cornerRadius = 10
    }
    
    override func viewDidLayoutSubviews() {
        postImageViewWidth = postImageView.frame.width
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action
    
    @IBAction func onCancelButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTweetButton(_ sender: Any) {
//        if tweetTextView.text.lengthOfBytes(using: String.Encoding.utf8) == 0 {
//            Utils.popAlertWith(msg: "Please type something to tweet about", in: self)
//        }
//        TwitterService.sharedInstance?.tweet(tweetTextView.text, replyTo: replyToTweet?.id, success: { (tweet: Tweet) in
//            print("successfully tweeted: \(tweet.text)")
//            self.delegate?.composeTweetViewController?(self, didTweet: tweet)
//            self.dismiss(animated: true, completion: nil)
//        }, failure: { (error: Error) in
//            Utils.popAlertWith(msg: "Tweet failed: \(error.localizedDescription)", in: self)
//        })
    }
    
    @IBAction func presentImagePicker(_ sender: Any) {
        var configuration = Configuration()
        configuration.recordLocation = false
        
        let imagePickerController = ImagePickerController(configuration: configuration)
        imagePickerController.imageLimit = 1
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func pickPlace(_ sender: UIButton) {
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePickerViewController(config: config)
        placePicker.delegate = self
        
        present(placePicker, animated: true, completion: nil)
    }
    
    private func getCurrentPlace() {
        
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            self.locationButton.setTitle("No current place", for: .normal)
            
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.locationButton.setTitle("\(place.name) - \(place.formattedAddress ?? "")", for: .normal)
                }
            }
        })
    }
    
    // MARK: - Navigation
    
    //override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
    
    //}
    
    override var inputAccessoryView: UIView? {
        return self.keyboardToolBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

extension ComposeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let tweet = postTextView.text else {
            return
        }
        
        let countDown = postCharLimit - tweet.lengthOfBytes(using: String.Encoding.utf8)
        countBarButton.title = String(countDown)
        
        if(countDown < 0){
            postButton.isEnabled = false
            countBarButton.tintColor = UIColor.red
        } else {
            postButton.isEnabled = true
            countBarButton.tintColor = UIColor.gray
        }
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        //add tool bar above keyboard
        countBarButton.title = "140"
        //tweetTextView.inputAccessoryView = self.keyboardToolBar
        
        return true
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ComposeViewController: ImagePickerDelegate {
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        if (images.count > 0) {
            let aspect = CGFloat(images[0].size.height / images[0].size.width)
            postImgViewHeightConstraint.constant = self.postImageView.frame.width * aspect
            postImageView.image = images[0]
        }
        
        dismiss(animated: true, completion: {
            self.becomeFirstResponder()
        })
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        self.becomeFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension ComposeViewController: GMSPlacePickerViewControllerDelegate {
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        self.locationButton.setTitle("\(place.name) - \(place.formattedAddress ?? "")", for: .normal)
        // Dismiss the place picker, as it cannot dismiss itself.
        viewController.dismiss(animated: true, completion: nil)
        
        print("Place name \(place.name)")
        print("Place address \(place.formattedAddress)")
        print("Place attributions \(place.attributions)")
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        // Dismiss the place picker, as it cannot dismiss itself.
        viewController.dismiss(animated: true, completion: nil)
        
        print("No place selected")
    }
}
