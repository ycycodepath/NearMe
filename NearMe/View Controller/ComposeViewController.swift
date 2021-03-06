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

protocol ComposeViewControllerDelegate {
    func composeViewController(_ composeViewController: ComposeViewController, didPost status: Post)
}

class ComposeViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var postImgScrollView: UIScrollView!
    
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet var keyboardToolBar: UIToolbar!
    @IBOutlet weak var countBarButton: UIBarButtonItem!
    @IBOutlet weak var locationButton: UIButton!
    
    @IBOutlet weak var postImgViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postImgViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var postImgScrollViewBottomConstraint: NSLayoutConstraint!
    
    var placesClient: GMSPlacesClient!
    
    var delegate: ComposeViewControllerDelegate?
    
    let postCharLimit = 140
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // height / width
    private var postImgAspect: CGFloat = 0
    
    private var gmsPlace: GMSPlace?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient.shared()
        getCurrentPlace()
        
        self.hideKeyboardWhenTappedAround()
        usernameLabel.text = Settings.globalSettings.userScreenname ?? "Ninja"
        
        profileImgView.image = Settings.globalSettings.userAvatarImage

        postTextView.delegate = self
        postTextView.becomeFirstResponder()
        
        postButton.isEnabled = false
        
        let cornerRadius = CGFloat(10)
        postImgScrollView.layer.cornerRadius = cornerRadius
        postImageView.layer.cornerRadius = cornerRadius
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.view.endEditing(true)
    }
    
    override func viewDidLayoutSubviews() {
        postImgViewWidthConstraint.constant = postImgScrollView.frame.size.width
        postImgScrollViewBottomConstraint.constant = keyboardToolBar.frame.height
        postImgViewHeightConstraint.constant = postImgViewWidthConstraint.constant * postImgAspect
        
        self.view.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action
    
    @IBAction func onCancelButton(_ sender: Any) {
        guard let rootTabBar = self.appDelegate.rootTabBarController else { return }
        //rootTabBar.tabBar.isHidden = false
        rootTabBar.selectedIndex = 0
        dismiss(animated: true, completion: nil)

        dismiss(animated: true, completion: nil)
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
                    self.gmsPlace = place
                    self.locationButton.setTitle("\(place.name) - \(place.formattedAddress ?? "")", for: .normal)
                }
            }
        })
    }
    
    @IBAction func onPost(_ sender: Any) {
        guard let gmsPlace = gmsPlace else {
            print("Sorry, I cannot get your location. Did you enable the location service?")
            return
        }
        
        let uuid = UIDevice.current.identifierForVendor?.uuidString
        let location = Location(latitude: gmsPlace.coordinate.latitude, longitude: gmsPlace.coordinate.longitude)
        
        let post = Post(uuid: uuid, message: self.postTextView.text, location: location, screen_name: Settings.globalSettings.userScreenname, place: gmsPlace.name, address: gmsPlace.formattedAddress, avatarUrl: Settings.globalSettings.userAvatarPath)
        
        let image = postImageView.image
        
        PostService.sharedInstance.create(post: post, image: image, success: { (post) in
            NSLog("Successfully createda a post")
            self.delegate?.composeViewController(self, didPost: post)
            guard let rootTabBar = self.appDelegate.rootTabBarController else { return }
            //rootTabBar.tabBar.isHidden = false
            rootTabBar.selectedIndex = 0
            self.dismiss(animated: true, completion: nil)

            self.dismiss(animated: true, completion: nil)
        }, failure: { (error) in
            print(error.localizedDescription)
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
            if countDown == postCharLimit {
                postButton.isEnabled = false
            } else {
                postButton.isEnabled = true
            }
            
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
            postImgAspect = CGFloat(images[0].size.height / images[0].size.width)
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
        self.gmsPlace = place
        self.locationButton.setTitle("\(place.name) - \(place.formattedAddress ?? "")", for: .normal)
        // Dismiss the place picker, as it cannot dismiss itself.
        viewController.dismiss(animated: true, completion: nil)
        
        print("Place name \(place.name)")
        print("Place address \(String(describing: place.formattedAddress))")
        print("Place attributions \(String(describing: place.attributions))")
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        // Dismiss the place picker, as it cannot dismiss itself.
        viewController.dismiss(animated: true, completion: nil)
        
        print("No place selected")
    }
}
