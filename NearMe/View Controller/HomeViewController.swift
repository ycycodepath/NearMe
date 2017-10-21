//
//  HomeViewController.swift
//  NearMe
//
//  Created by Mandy Chen on 10/11/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import IDMPhotoBrowser

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, IDMPhotoBrowserDelegate {

    @IBOutlet weak var tableView: UITableView!
    var searchController: UISearchController!
    var posts = [Post]()
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentRadius = 5.00
    let defaultLocation = CLLocation(latitude:37.3743507,longitude:-121.8825989)
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        initLocation()
        initRefreshControl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedCell
        cell.post = posts[indexPath.row]
        cell.handleFeedImageTapped = { (imageView, post) in
            
            let image = imageView.image!

            // Create an array to store IDMPhoto objects
            var photos: [IDMPhoto] = []
    
            var photo: IDMPhoto
    

            photo = IDMPhoto.init(image: image)
            photo.caption = post.message
            photos.append(photo)
    
            // Create and setup browser
//            let browser: IDMPhotoBrowser = IDMPhotoBrowser.init(photos: photos, animatedFrom: imageView)
            let browser: IDMPhotoBrowser = IDMPhotoBrowser.init(photos: photos)
            browser.delegate = self
            browser.displayActionButton = false
            browser.displayArrowButton = false
            browser.displayCounterLabel = true
            browser.usePopAnimation = true
            browser.dismissOnTouch = true
//            browser.scaleImage = image
    
            // Show
            self.present(browser, animated: true, completion: nil)
            
        }
        
        cell.handleLikeButtonClicked = { (post) in
            
            LikeService.sharedInstance.syncCoreData(postId: post.id, success: { (liked) in
                
                PostService.sharedInstance.updateLikeCount(postId: post.id, liked: liked, success: {
                    print ("Success")
                }, failure: { (error) in
                    print(error.localizedDescription)
                })
                
            }, failure: { (error) in
                print(error.localizedDescription)
            })
            
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }

    func initSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.sizeToFit()
        view.addSubview(searchController.searchBar)
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let keywords = searchController.searchBar.text {
           
            tableView.reloadData()
        }
    }
    
    func initLocation() {
        locationManager = CLLocationManager()
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            if ((UIDevice.current.systemVersion as NSString).floatValue >= 8) {
                locationManager.requestWhenInUseAuthorization()
            }
            locationManager.startUpdatingLocation()
        } else {
            print("Location services are not enabled");
        }
    }

    func getPost(location: CLLocation, radius: Double) -> Void {
        print("getting posts")
        print("location: \(location), radius: \(radius)")
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
            print("self.posts.count: \(self.posts.count)")
            print("posts.count before assigning value: \(posts.count)")
            self.posts = posts.reversed()
            self.tableView.reloadData()
        }, failure: { (error: Error) in
            self.showError(error: error)
        })
    }

    func refreshPost(location: CLLocation, radius: Double) -> Void {
        print("refreshing posts")
        print("location: \(location), radius: \(radius)")
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
            self.posts = posts.reversed()
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
            print("posts.count: \(posts.count)")
        }, failure: { (error: Error) in
            self.showError(error: error)
            print("posts.count: error")
        })
    }
    
    
    // MARK: - Pull and Refresh
    func initRefreshControl() {
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
         refreshPost(location: self.currentLocation!, radius: currentRadius)
    }
    
    func showError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
            let fakeLocation = defaultLocation
            self.currentLocation = fakeLocation
            print("currentLocation: \(self.currentLocation)")
            getPost(location: self.currentLocation!, radius: currentRadius)
        }
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        if ((error) != nil) {
            print(error)
        }
    }
}

