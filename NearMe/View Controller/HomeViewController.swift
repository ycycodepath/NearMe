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

enum ViewType {
    case List
    case Map
}

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, IDMPhotoBrowserDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: UIView!
    
    @IBOutlet var leftBarButton: UIBarButtonItem!
    @IBOutlet var rightBarButton: UIBarButtonItem!
    
    
    var currentViewType = ViewType.List
    
    var posts = [Post]()
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var currentRadius = 5.00
    let defaultLocation = CLLocation(latitude:37.3743507,longitude:-121.8825989)
    
    var mapContentView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    let DEFAULT_LATITUDE = 37.3743507
    let DEFAULT_LONGITUDE = -121.8825989
    var postLocations: [CLLocationCoordinate2D] = []
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        initLocation()
        initTableView()
        initMapView()
        
        initRefreshControl()
        initSearchBar()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /** MARK: - Get Permission and Data **/
    func initLocation() {
        locationManager = CLLocationManager()
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 50
            locationManager.delegate = self

            if ((UIDevice.current.systemVersion as NSString).floatValue >= 8) {
                locationManager.requestWhenInUseAuthorization()
            }
            locationManager.requestLocation()
        } else {
            print("Location services are not enabled");
        }
    }

    func getPost(location: CLLocation, radius: Double) -> Void {
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
            self.posts = posts.reversed()
            self.tableView.reloadData()
            self.showPostsInMapView()
        }, failure: { (error: Error) in
            self.showError(error: error)
        })
    }


    /** MARK: - Switch UI View **/
    @IBAction func onSwitchView(_ sender: Any) {
        switch currentViewType {
            case ViewType.List:
                self.view.bringSubview(toFront: mapView)
                currentViewType = ViewType.Map
                break
            case ViewType.Map:
                self.view.bringSubview(toFront: tableView)
                currentViewType = ViewType.List
                break
            default:
                ()
        }
    }
    
    /** MARK: - Table View **/
    func initTableView(){
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
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
            browser.displayDoneButton = false
            browser.displayArrowButton = false
            browser.displayCounterLabel = true
            browser.usePopAnimation = true
            browser.dismissOnTouch = true
    
            // Show
            self.present(browser, animated: true, completion: nil)
            
        }
        
        cell.handleLikeButtonClicked = { (post) in
            
            LikeService.sharedInstance.syncCoreData(postId: post.id, success: { (liked) in
                
                //update like count label
                if liked {
                    cell.post.likes? += 1
                } else {
                    cell.post.likes? -= 1
                }
                
                cell.likeCountLabel.text = "\(cell.post.likes ?? 0)"
                
                //update firebase db
                PostService.sharedInstance.updateLikeCount(postId: post.id, liked: liked, success: {
                    
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
    
    
    
    /** MARK: - Map View **/
    func initMapView(){
        placesClient = GMSPlacesClient.shared()
        
        let camera = GMSCameraPosition.camera(withLatitude: DEFAULT_LATITUDE,
                                              longitude: DEFAULT_LONGITUDE,
                                              zoom: zoomLevel)
        mapContentView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapContentView.delegate = self
        mapContentView.settings.myLocationButton = true
        mapContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapContentView.isMyLocationEnabled = true
        // Add the map to the view, hide it until we've got a location update.
        mapView.addSubview(mapContentView)
    }
    
    
    func showPostsInMapView() {
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
            state_marker.map = mapContentView
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
    
    
    /** MARK: - Search Bar **/
    func initSearchBar() {

        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        searchController?.searchBar.sizeToFit()
        navigationItem.titleView = searchController?.searchBar
        searchController?.searchBar.delegate = self
        
        definesPresentationContext = true
        
        searchController?.hidesNavigationBarDuringPresentation = false
    }
    
    
    
    /** MARK: - Pull and Refresh **/
    func initRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
         refreshPost(location: self.currentLocation!, radius: currentRadius)
    }
    
    
    func refreshPost(location: CLLocation, radius: Double) -> Void {
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
            self.posts = posts.reversed()
            self.tableView.reloadData()
            self.showPostsInMapView()
            self.refreshControl.endRefreshing()
        }, failure: { (error: Error) in
            self.showError(error: error)
        })
    }
    
    
    /** MARK: - Error window **/
    func showError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}


extension HomeViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = MapInfoWindow(frame: CGRect(x:0,y:0,width:200,height:65))
        infoWindow.screenName = marker.title
        infoWindow.message = marker.snippet
        
        return infoWindow
    }
    
}

extension HomeViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let location = locations.last {
            self.currentLocation = location
            getPost(location: location, radius: currentRadius)
            
            let camera = GMSCameraPosition.camera(withLatitude:location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: zoomLevel)
            if mapView.isHidden {
                mapContentView.camera = camera
            } else {
                mapContentView.animate(to: camera)
            }
        }
        
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
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
        if ((error) != nil) {
            print(error)
        }
    }
}

extension HomeViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.navigationItem.setLeftBarButton(nil, animated: true)
        self.navigationItem.setRightBarButton(nil, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.navigationItem.setLeftBarButton(nil, animated: true)
        self.navigationItem.setRightBarButton(nil, animated: true)
    }
}

// Handle the user's selection.
extension HomeViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
        
        let locationSearched = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        getPost(location: locationSearched, radius: currentRadius)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

