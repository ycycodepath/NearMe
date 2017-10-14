//
//  GeoService.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/11/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation
import Firebase
import GeoFire
import PromiseKit
import SwiftyBeaver

class GeoService {
    
    static let sharedInstance = GeoService()
    
    var databaseRef: DatabaseReference
    var postGeoDataRef: DatabaseReference
    var geofire: GeoFire
    var postGeoResponses = [PostGeo]()
    let milesPerMeter = 0.000621371

    init() {
        databaseRef = Database.database().reference()
        postGeoDataRef = databaseRef.child("postGeos")
        geofire = GeoFire(firebaseRef: postGeoDataRef)
    }
    
    func create (location: CLLocation?, key: String?, success: (() -> Void)!, failure: ((Error) -> Void)!) {
        
        guard let location = location else {
            failure(ServiceError.postGeoDataError)
            return
        }
        
        guard let key = key else {
            failure(ServiceError.postGeoDataError)
            return
        }
        
        geofire.setLocation(location, forKey: key) { (error) in
            
            guard let error = error else {
                success()
                return
            }
            failure(error)
        }
    }
    
    func search (center: CLLocation?, radius: Double?, success: (([PostGeo]) -> Void)!,
         failure: ((Error) -> Void)!) {
 
        guard let center = center else {
            failure(ServiceError.postGeoDataError)
            return
        }
        
        guard let radius = radius, radius >= 0.0 else {
            failure(ServiceError.postGeoDataError)
            return
        }
        
        guard let circleQuery = geofire.query(at: center, withRadius: radius) else {
            failure(ServiceError.geoServiceError)
            return
        }
        
         SwiftyBeaver.info("entered search...")
        
        postGeoResponses = [PostGeo]()
        //the observer method listens for new data that matches the query
        // if param center changes then circleQuery's location changes and it will trigger observe method to load existing matching records and will get to observeReady after existing all records matching the query criteria are loaded
        // whenever search is invoked and circleQuery is set (again), it will also load all existing records and go to observerReady after existing all records matching the query criteria are loaded.
        //after search function completes, whenver a record is inserted into geo database and matches the circleQuer's search, the new record will be observed/catght by observer below and trigger the with completion block
        
        circleQuery.observe(.keyEntered, with: { (key, location) in
            if let key = key, let location = location {
                SwiftyBeaver.debug("entered a key: " + key)
                let distanceFromUser = center.distance(from: location)
                let distance = String(format: "%.2f mi", self.milesPerMeter * distanceFromUser)
                print(distance)
                let postGeoResponse = PostGeo(id: key, distance: distance)
                self.postGeoResponses.append(postGeoResponse)
            }
        })
        
        circleQuery.observe(.keyExited) { (key, location) in
            if let key = key {
                print("exited a key: " + key)
            }
        }
        
        circleQuery.observeReady({
            SwiftyBeaver.info("initial async loading is done")
            success(self.postGeoResponses)
        })
    }
}
