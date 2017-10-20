//
//  MapViewController.swift
//  NearMe
//
//  Created by Mandy Chen on 10/13/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController, GMSMapViewDelegate {
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    let DEFAULT_LATITUDE = 37.3743507
    let DEFAULT_LONGITUDE = -121.8825989
    var postLocations: [CLLocationCoordinate2D] = []
    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self
        
        placesClient = GMSPlacesClient.shared()
        
        let camera = GMSCameraPosition.camera(withLatitude: DEFAULT_LATITUDE,
                                              longitude: DEFAULT_LONGITUDE,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.delegate = self
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        // Add the map to the view, hide it until we've got a location update.
        view.addSubview(mapView)
        mapView.isHidden = true
        
        getPosts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getPosts() {
        postLocations.removeAll()
        for post in posts {
            let state_marker = GMSMarker()
            let post_latitude = post.location?.latitude ?? DEFAULT_LATITUDE
            let post_longitude = post.location?.longitude ?? DEFAULT_LONGITUDE
            let post_location = checkIfMutlipleCoordinates(latitude: post_latitude, longitude: post_longitude)
            postLocations.append(post_location)
            
            state_marker.position = CLLocationCoordinate2D(latitude: post_location.latitude, longitude: post_location.longitude)
            state_marker.title = post.screen_name
            state_marker.snippet = post.message
            state_marker.map = mapView
        }
    }
    
    func checkIfMutlipleCoordinates(latitude : Double , longitude : Double) -> CLLocationCoordinate2D{
        
        var lat = latitude
        var lng = longitude
        var finalPos = CLLocationCoordinate2D()
        
        let arrTemp = self.postLocations.filter {
            
            return (((latitude == $0.latitude) && (longitude == $0.longitude)))
        }
        
        if arrTemp.count > 0 {
            // Core Logic giving minor variation to similar lat long
            
            let variation = (randomDouble(min: 0.0, max: 2.0) - 0.5) / 1500
            lat = lat + variation
            lng = lng + variation
            finalPos = checkIfMutlipleCoordinates(latitude: lat, longitude: lng)
        } else {
            finalPos = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        }
        return  finalPos
    }
    
    func randomDouble(min: Double, max:Double) -> Double {
        return (Double(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        print("setting markerInfoWindow")
        let infoWindow = MapInfoWindow(frame: CGRect(x:0,y:0,width:200,height:65))
        infoWindow.screenName = marker.title
        infoWindow.message = marker.snippet
        
        return infoWindow
    }
}

//extension MapViewController: GMSMapViewDelegate {
//    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
//        print("setting markerInfoWindow")
//        let infoWindow :MapInfoWindow = Bundle.main.loadNibNamed("MapInfoWindow", owner: self, options: nil)![0] as! MapInfoWindow
//
//        infoWindow.screenNameLabel.text = marker.title
//        infoWindow.messageLabel.text = marker.snippet
//
//        return infoWindow
//    }
//
//}

extension MapViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
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
        print("Error: \(error)")
    }
}
