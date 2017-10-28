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
    var searchLocation: CLLocation!
    var searchPlace: GMSPlace?

    let defaultLocation = CLLocation(latitude:37.3743507,longitude:-121.8825989)
    let CURRENT_LOCATION_PLACEHOLDER = "Current Location"
    
    var mapContentView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    let DEFAULT_LATITUDE = 37.3743507
    let DEFAULT_LONGITUDE = -121.8825989
    var postLocations: [CLLocationCoordinate2D] = []
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
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
            self.posts = posts.sorted(by: self.sortFunc)
            if self.currentViewType == .List {
                self.tableView.reloadData()
            } else if self.currentViewType == .Map {
                self.showPostsInMapView()
            }
            self.getSearchBarPlaceholder()
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
                self.leftBarButton.image = UIImage(named: "list")
                self.tableView.reloadData()
                break
            case ViewType.Map:
                self.view.bringSubview(toFront: tableView)
                currentViewType = ViewType.List
                self.leftBarButton.image = UIImage(named: "map")
                self.showPostsInMapView()
                break
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
                    self.posts[indexPath.row].likes? += 1
                } else {
                    cell.post.likes? -= 1
                    self.posts[indexPath.row].likes? -= 1
                }
                
                cell.likeCountLabel.text = "\(cell.post.likes ?? 0)"
                if cell.post.likes != nil && cell.post.likes! >= 500 {
                    cell.fireImageView.isHidden = false
                } else {
                    cell.fireImageView.isHidden = true
                }
                
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
        mapView.addSubview(mapContentView)
    }
    
    
    func showPostsInMapView() {
        postLocations.removeAll()
        mapContentView.clear()
        updateMapCamera()
        for post in posts {
            let state_marker = GMSMarker()
            let post_latitude = post.location?.latitude ?? DEFAULT_LATITUDE
            let post_longitude = post.location?.longitude ?? DEFAULT_LONGITUDE
            let post_location = checkIfMutlipleCoordinates(latitude: post_latitude, longitude: post_longitude)
            postLocations.append(post_location)
            
            state_marker.position = CLLocationCoordinate2D(latitude: post_location.latitude, longitude: post_location.longitude)
            state_marker.title = post.screen_name
            state_marker.snippet = post.message
            state_marker.userData = post
            state_marker.map = mapContentView
        }
    }
    
    func updateMapCamera() {
        let camera = GMSCameraPosition.camera(withLatitude:searchLocation.coordinate.latitude, longitude: searchLocation.coordinate.longitude, zoom: zoomLevel)
        if mapView.isHidden {
            mapContentView.camera = camera
        } else {
            mapContentView.animate(to: camera)
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
        let filter = GMSAutocompleteFilter()
        filter.country = Locale.current.regionCode
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        resultsViewController?.autocompleteFilter = filter

        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        //searchController?.searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        //searchController?.searchBar.sizeToFit()
        searchController?.searchBar.delegate = self
        searchController?.searchBar.placeholder = CURRENT_LOCATION_PLACEHOLDER
        searchController?.searchBar.showsCancelButton = false
        searchController?.searchBar.tintColor = UIColor.white

//        searchController?.searchBar.barStyle = .black
//        searchController?.searchBar.backgroundColor = UIColor.lightGray
//        searchController?.searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
//        searchController?.searchBar.frame.size.width = 40
//        searchController?.searchBar.sizeToFit()
//        searchController?.searchBar.frame.size.height = 40
//        navigationItem.titleView = searchController?.searchBar
//        let yConstraint = NSLayoutConstraint(item: navigationItem.titleView, attribute: .centerY, relatedBy: .equal, toItem: navigationItem.leftBarButtonItem?.image, attribute: .centerY, multiplier: 1, constant: 0)
//        NSLayoutConstraint.activate([yConstraint])

        definesPresentationContext = true
        
        searchController?.hidesNavigationBarDuringPresentation = false
    }
    
    @IBAction func onSearchButtonClicked(_ sender: Any) {
        
        navigationBarInSearch()
    }
    
    
    func navigationBarInSearch() {
        let currentLocationButton = UIBarButtonItem(image: UIImage(named: "currentLocation"), style: .plain, target: self, action: #selector(chooseCurrentLocation))
        self.navigationItem.setLeftBarButton(currentLocationButton, animated: true)
        self.navigationItem.titleView = searchController?.searchBar
        self.navigationItem.setRightBarButton(nil, animated: true)
    }
    
    func navigationBarInNormal() {
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        self.navigationItem.titleView = nil
        self.navigationItem.title = "Home"
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
    }
    
    func getSearchBarPlaceholder() {
        if ( currentLocation == searchLocation ) {
            searchController?.searchBar.placeholder = CURRENT_LOCATION_PLACEHOLDER
        } else {
            searchController?.searchBar.placeholder = searchPlace?.name
        }
    }
    
    @objc func chooseCurrentLocation() {
        searchController?.isActive = false
        searchLocation = currentLocation
        getPost(location: searchLocation!, radius: Settings.globalSettings.distance)
    }
    
    /** MARK: - Pull and Refresh **/
    func initRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
         refreshPost(location: self.searchLocation!, radius: Settings.globalSettings.distance)
    }
    
    
    func refreshPost(location: CLLocation, radius: Double) -> Void {
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
            self.posts = posts.sorted(by: self.sortFunc)
            if self.currentViewType == .List {
                self.tableView.reloadData()
            } else if self.currentViewType == .Map {
                self.showPostsInMapView()
            }
            self.refreshControl.endRefreshing()
        }, failure: { (error: Error) in
            self.showError(error: error)
        })
    }
    
    private func sortFunc(left: Post, right: Post) -> Bool {
        switch Settings.globalSettings.sortBy {
        case .mostRecent:
            return (left.creationTimestamp ?? -1) > (right.creationTimestamp ?? -1)
        case .distance:
            return (Double(left.distance ?? "") ?? -1) < (Double(right.distance ?? "") ?? -1)
        case .mostLiked:
            return (left.likes ?? -1) > (right.likes ?? -1)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? UINavigationController {
            if let composeViewController = destinationViewController.topViewController as? ComposeViewController {
                composeViewController.delegate = self
            }
        }
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
        let infoWindow = MapInfoWindow(frame: CGRect(x:0,y:0,width:view.frame.width*2/3,height:400))
        infoWindow.screenName = marker.title
        infoWindow.message = marker.snippet
        
        let map_post = marker.userData as! Post
        infoWindow.likeCount = "\(map_post.likes ?? 0)"
        
        if let createTime = map_post.creationTimestamp {
            infoWindow.timeStamp = FeedCell.convertEpochTimeStamp(timestamp: createTime)
        }
        
        // TODO: let user picks up avatar image
        infoWindow.avatar = UIImage(named: "user1")
        
        if let imageUrlStr = map_post.imageUrl, let imageUrl = URL(string: imageUrlStr), let data = try? Data(contentsOf: imageUrl) {
            infoWindow.postImage =  UIImage(data: data)
        } else {
            infoWindow.postImageHeightConstraint.constant = 0
        }
        infoWindow.frame.size.height =  infoWindow.totalHeightConstraint + infoWindow.postImageHeightConstraint.constant + infoWindow.messageLabel.frame.height
        infoWindow.contentView.layoutIfNeeded()
        return infoWindow
    }
    
}

extension HomeViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let location = locations.last {
            currentLocation = location
            if searchLocation == nil {
                searchLocation = currentLocation
            }
            getPost(location: searchLocation!, radius: Settings.globalSettings.distance)
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
        print(error)
    }
}

extension HomeViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchController?.searchBar.showsCancelButton = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationBarInNormal()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationBarInNormal()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        navigationBarInSearch()
    }
    
}


extension HomeViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        searchPlace = place
        searchLocation = CLLocation(latitude: searchPlace!.coordinate.latitude, longitude: searchPlace!.coordinate.longitude)
        getPost(location: searchLocation!, radius: Settings.globalSettings.distance)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
extension HomeViewController: ComposeViewControllerDelegate {
    func composeViewController(_ composeViewController: ComposeViewController, didPost status: Post) {
        self.posts.insert(status, at: 0)
        self.tableView.reloadData()
    }
}

