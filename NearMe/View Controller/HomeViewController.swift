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
import MBProgressHUD

enum ViewType {
    case List
    case Map
}

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, IDMPhotoBrowserDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: UIView!
    
    @IBOutlet var leftBarButton: UIBarButtonItem!
    @IBOutlet var rightBarButton: UIBarButtonItem!
    
    @IBOutlet weak var refreshMapButton: UIButton!
    
    var currentViewType = ViewType.List
    
    var posts = [Post]()
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation!
    var searchLocation: CLLocation!
    var searchPlace: GMSPlace?

    let defaultLocation = CLLocation(latitude:37.3743507,longitude:-121.8825989)
    let CURRENT_LOCATION_PLACEHOLDER = "Current Location"
    
    var mapContentView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 15.0
    let DEFAULT_LATITUDE = 37.3743507
    let DEFAULT_LONGITUDE = -121.8825989
    let GEO_EPSILON = 0.000001
    var postLocations: [CLLocationCoordinate2D] = []
    var isDragged = false
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    let refreshControl = UIRefreshControl()
    
    let errorTitle = "Error"
    let noPostErrorTitle = "No Post"
    let noPostErrorMessage =  "Be the first one to post here!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        
        initLocation()
        initTableView()
        
        initRefreshControl()
        initSearchBar()
        refreshMapButton.layer.cornerRadius = 0.5 * refreshMapButton.bounds.size.width
        refreshMapButton.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.2)
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

    func getPost(location: CLLocation, radius: Double, zoom: Float) -> Void {
//        MBProgressHUD.showAdded(to: self.view, animated: true)
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
//            MBProgressHUD.hide(for: self.view, animated: true)
            self.posts = posts.sorted(by: self.sortFunc)
            if self.currentViewType == .List {
                self.tableView.reloadData()
                
                if posts.count > 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            } else if self.currentViewType == .Map {
                self.showPostsInMapView(zoom: zoom)
            }

            self.getSearchBarPlaceholder()
            if ( posts.count == 0 && self.currentViewType == ViewType.List ) {
                self.showError(title: self.noPostErrorTitle, message:self.noPostErrorMessage )
            }
        }, failure: { (error: Error) in
//            MBProgressHUD.hide(for: self.view, animated: true)
            self.showError(title: self.errorTitle, message: error.localizedDescription)
        })
    }


    /** MARK: - Switch UI View **/
    @IBAction func onSwitchView(_ sender: Any) {
        switch currentViewType {
            case ViewType.List:
                self.view.bringSubview(toFront: mapView)
                currentViewType = ViewType.Map
                self.leftBarButton.image = UIImage(named: "list")
                initMapView()
                self.showPostsInMapView(zoom: zoomLevel)
                break
            case ViewType.Map:
                self.view.bringSubview(toFront: tableView)
                currentViewType = ViewType.List
                self.leftBarButton.image = UIImage(named: "map")
                self.tableView.reloadData()
                mapContentView = nil
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
        mapContentView = GMSMapView.map(withFrame: mapView.bounds, camera: camera)
        mapContentView.delegate = self
        mapContentView.settings.myLocationButton = false
        mapContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapContentView.isMyLocationEnabled = true
        mapContentView.setMinZoom(13, maxZoom: 20.0)
        mapView.addSubview(mapContentView)
        mapView.bringSubview(toFront: refreshMapButton)
    }
    
    
    func showPostsInMapView(zoom: Float) {
        postLocations.removeAll()
        mapContentView.clear()
        updateMapCamera(zoom: zoom)
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
            if let likeCount = post.likes {
                if ( likeCount > 50 ) {
                    state_marker.icon = UIImage(named: "hotMarker")
                } else {
                     state_marker.icon = UIImage(named: "Marker")
                }
            }
            state_marker.map = mapContentView
        }
    }
    
    func updateMapCamera(zoom: Float) {
        let camera = GMSCameraPosition.camera(withLatitude:(searchLocation?.coordinate.latitude)!, longitude: (searchLocation?.coordinate.longitude)!, zoom: zoom)
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

        definesPresentationContext = true
        
        searchController?.hidesNavigationBarDuringPresentation = false
    }
    
    @IBAction func onSearchButtonClicked(_ sender: Any) {
        
        navigationBarInSearch()
    }
    
    
    func navigationBarInSearch() {
        let currentLocationButton = UIBarButtonItem(image: UIImage(named: "currentLocation"), style: .plain, target: self, action: #selector(chooseCurrentLocation))
        self.navigationItem.setLeftBarButton(currentLocationButton, animated: true)

        self.navigationItem.setRightBarButton(nil, animated: true)
        self.navigationItem.searchController = searchController
        searchController?.searchBar.becomeFirstResponder()
    }
    
    func navigationBarInNormal() {
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        self.navigationItem.searchController = nil
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
    }
    
    func getSearchBarPlaceholder() {
        if ( fabs( currentLocation.coordinate.latitude - searchLocation.coordinate.latitude ) <= GEO_EPSILON && fabs( currentLocation.coordinate.longitude - searchLocation.coordinate.longitude ) <= GEO_EPSILON ) {
            searchController?.searchBar.placeholder = CURRENT_LOCATION_PLACEHOLDER
            self.navigationItem.title = CURRENT_LOCATION_PLACEHOLDER
        } else if let searchPlaceName = searchPlace?.name {
            searchController?.searchBar.placeholder = searchPlaceName
            self.navigationItem.title = searchPlaceName
        }
    }
    
    @objc func chooseCurrentLocation() {
        searchController?.isActive = false
        searchLocation = currentLocation
        getPost(location: searchLocation!, radius: Settings.globalSettings.distance, zoom: zoomLevel)
    }
    
    /** MARK: - Pull and Refresh **/
    func initRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    
    @objc func refreshControlAction(_ refreshControl: UIRefreshControl) {
        if let location = self.searchLocation {
            refreshPost(location: location, radius: Settings.globalSettings.distance)
        } else {
            self.refreshControl.endRefreshing()
        }
    }
    
    
    func refreshPost(location: CLLocation, radius: Double) -> Void {
        PostService.sharedInstance.search(center: location, radius: radius, success: { (posts: [Post]) in
            self.posts = posts.sorted(by: self.sortFunc)
            if self.currentViewType == .List {
                self.tableView.reloadData()
            } else if self.currentViewType == .Map {
                self.showPostsInMapView(zoom: self.zoomLevel)
            }
            self.refreshControl.endRefreshing()
        }, failure: { (error: Error) in
            self.refreshControl.endRefreshing()
            self.showError(title: self.errorTitle, message: error.localizedDescription)
        })
    }
    
    @IBAction func onRefreshMapButton(_ sender: Any) {
        searchLocation = CLLocation( latitude: mapContentView.camera.target.latitude, longitude: mapContentView.camera.target.longitude )
        getPost(location: searchLocation, radius: mapContentView.getRadius(), zoom: mapContentView.camera.zoom)
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
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}


extension HomeViewController: GMSMapViewDelegate {

    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = MapInfoWindow(frame: CGRect(x:0,y:0,width:view.frame.width*2/3,height:400))
        infoWindow.post = marker.userData as! Post
        infoWindow.frame.size.height =  infoWindow.totalHeightConstraint + infoWindow.postImageHeightConstraint.constant + infoWindow.messageLabel.frame.height
        infoWindow.contentView.layoutIfNeeded()
        return infoWindow
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        mapView.selectedMarker = marker;
        let position = marker.position
        
        let camera = GMSCameraPosition.camera(withLatitude:position.latitude+0.006, longitude: position.longitude, zoom: zoomLevel)
        
        mapContentView.animate(to: camera)

        return true;
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let location = locations.last {
            currentLocation = location
            let neBoundsCorner = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude + 3,
                                                        longitude: currentLocation.coordinate.longitude + 3)
            let swBoundsCorner = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude - 3,
                                                        longitude: currentLocation.coordinate.longitude - 3)
            let bounds = GMSCoordinateBounds(coordinate: neBoundsCorner, coordinate: swBoundsCorner)
            resultsViewController?.autocompleteBounds = bounds
            
            if searchLocation == nil {
                searchLocation = currentLocation
            }
            getPost(location: searchLocation!, radius: Settings.globalSettings.distance, zoom: zoomLevel)
        } else {
            currentLocation = defaultLocation
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
        getPost(location: searchLocation!, radius: Settings.globalSettings.distance, zoom: zoomLevel)
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
        
        guard let postLocation = status.location, let postLatitude = postLocation.latitude, let postLongitude = postLocation.longitude else {
            return
        }
        let postCLLocation: CLLocation = CLLocation(latitude: postLatitude, longitude: postLongitude)
        let distanceFromUser = searchLocation.distance(from: postCLLocation)
        let distance = distanceFromUser/1000
        
        if distance <= Settings.globalSettings.distance {
            var newPost = status
            newPost.distance = "\(distance)"
            self.posts.insert(newPost, at: 0)
            self.tableView.reloadData()
        }
    }
}

extension GMSMapView {
    func getCenterCoordinate() -> CLLocationCoordinate2D {
        let centerPoint = self.center
        let centerCoordinate = self.projection.coordinate(for: centerPoint)
        return centerCoordinate
    }
    
    func getTopCenterCoordinate() -> CLLocationCoordinate2D {
        let topCenterCoor = self.convert(CGPoint(x: self.frame.size.width, y: 0), from: self)
        let point = self.projection.coordinate(for: topCenterCoor)
        return point
    }
    
    func getRadius() -> CLLocationDistance {
        let centerCoordinate = getCenterCoordinate()
        let centerLocation = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
        let topCenterCoordinate = self.getTopCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
        let radius = CLLocationDistance(centerLocation.distance(from: topCenterLocation))/1000.0
        return round(radius)
    }
}
