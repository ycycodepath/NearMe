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

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {

    @IBOutlet weak var tableView: UITableView!
    var searchController: UISearchController!
    var posts = [Post]()
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentRadius = 5.00
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        initLocation()
//        initSearchBar()
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
        let post = posts[indexPath.row]
        cell.post = post
        return cell
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
        print("\(location), \(radius)")
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
            self.posts = posts
            print("posts.count: \(posts.count)")
            self.tableView.reloadData()
        }, failure: { (error: Error) in
            self.showError(error: error)
            print("posts.count: error")
        })
    }

    func showError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    
}

extension HomeViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationManager.stopUpdatingLocation()
            let fakeLocation = CLLocation(latitude:37.3743507,longitude:-121.8825989)
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

