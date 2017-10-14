//
//  ViewController.swift
//  NearMe
//
//  Created by Xiang Yu on 10/6/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit
import CoreLocation
import FLEX
import SwiftyBeaver

class ViewController: UIViewController, CLLocationManagerDelegate {

    var locationManager: CLLocationManager!
    var userCurrentLocation: CLLocation!
    var count: Int = 20

    override func viewDidLoad() {
        super.viewDidLoad()
        //FLEXManager.shared().showExplorer()
        // Do any additional setup after loading the view, typically from a nib.
        
        //radius: km
        getCurrentLocation()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        //getCurrentLocation()
    }
    
    @IBAction func onCreatePostButtonClicked(_ sender: Any) {
        
        let image = UIImage(named: "ig")
        let uuid = UIDevice.current.identifierForVendor?.uuidString
        let message = "It's beautiful"
        
        let centerLocation = Location(latitude: userCurrentLocation.coordinate.latitude, longitude: userCurrentLocation.coordinate.longitude)
//        print("latitude \(centerLocation.latitude) longitude: \(centerLocation.longitude)")
//        let centerLocation = CLLocation(latitude: 37.7833, longitude: -122.4167)
//        let centerLocation = Location(latitude: 37.8833, longitude: -122.5167)

        
        
        let post = Post(uuid: uuid, message: message, location: centerLocation, screen_name: "Super Mario", place: "Peet's Coffee", address: "1234 ABC Blvd, Menlo Park, CA 94528")
        
        PostService.sharedInstance.create(post: post, image: image, success: {
            NSLog("Successfully createda a post")
        }, failure: { (error) in
            print(error.localizedDescription)
        })
       
        
    }
    
    func getCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
//        manager.stopUpdatingLocation()
//        self.userCurrentLocation = locations[0] as CLLocation

        if let location = locations.first {
//            count-=1
//            print("Found user's location: \(location)")
//
//            if count <= 0 {
//                updateLocation()
//                locationManager.stopUpdatingLocation()
//
//            } else {
//                userCurrentLocation = location
//            }
//
//
//            print("user latitude = \(userCurrentLocation.coordinate.latitude)")
//            print("user longitude = \(userCurrentLocation.coordinate.longitude)")
            
              locationManager.stopUpdatingLocation()
              userCurrentLocation = location
            
            PostService.sharedInstance.search(center: userCurrentLocation, radius: 15.0, success: { (posts) in
                SwiftyBeaver.error(posts.count)
            }) { (error) in
                print(error.localizedDescription)
            }

        }

    }
    
    @IBAction func onSearchButtonClicked(_ sender: Any) {
        
                PostService.sharedInstance.search(center: userCurrentLocation, radius: 15.0, success: { (posts) in
                    SwiftyBeaver.info(posts.count)
                }) { (error) in
                    print(error.localizedDescription)
                }

    
    }
    

    func updateLocation() {
        
        let centerLocation = CLLocation(latitude: 37.7833, longitude: -122.4167)
        userCurrentLocation = centerLocation

    }
    
    @IBAction func onChangeLocation(_ sender: Any) {
        
                let centerLocation = CLLocation(latitude: 37.7833, longitude: -122.4167)
                userCurrentLocation = centerLocation
                locationManager.stopUpdatingLocation()

    }
    
    @IBAction func onCreateImageButtonClicked(_ sender: Any) {
        
    }
    
}

