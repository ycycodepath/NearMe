//
//  PostService.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/10/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation
import Firebase
import GeoFire
import PromiseKit

class PostService {
    
    static let sharedInstance = PostService()
    
    var databaseRef: DatabaseReference
    var postDatabaseRef: DatabaseReference
    
    init() {
        databaseRef = Database.database().reference()
        postDatabaseRef = databaseRef.child("posts")
    }
    
    func create (post: Post?, image: UIImage?, success: (() -> Void)!, failure: ((Error) -> Void)!) {
        
        guard let post = post else {
            failure(ServiceError.postDataError)
            return
        }
        
        guard let uuid = post.uuid else {
            failure(ServiceError.postDataError)
            return
        }
        
        guard let message = post.message else {
            failure(ServiceError.postDataError)
            return
        }
        
        guard let postLocation = post.location, let postLatitude = postLocation.latitude, let postLongitude = postLocation.longitude else {
            failure(ServiceError.postDataError)
            return
        }
        
        let postCLLocation: CLLocation = CLLocation(latitude: postLatitude, longitude: postLongitude)
        
        var values = ["uuid": uuid,
                      "message": message,
                      "imageUrl": post.imageUrl ?? "",
                      "creationTimestamp": ServerValue.timestamp(),
                      "likes": 0,
                      "location": ["latitude": postLatitude, "longitude": postLongitude],
                      "screen_name": post.screen_name ?? "Anonymous Author",
                      "place": post.place ?? "",
                      "address": post.address ?? ""]
            as [String: Any]
        
        if let image = image {
            
            ImageService.sharedInstance.create(image: image, success: { (imageUrl) in
                values["imageUrl"] = imageUrl
                self.insertPost(values, postCLLocation, success, failure)
            }) { (error) in
                print(error.localizedDescription)
            }
        } else {
            insertPost(values, postCLLocation, success, failure)
        }
    }
    
    fileprivate func insertPost(_ values: [String : Any], _ postCLLocation: CLLocation, _ success: (() -> Void)!, _ failure: ((Error) -> Void)!) {
        let newPostDatabaseRef = postDatabaseRef.childByAutoId()
        newPostDatabaseRef.updateChildValues(values) { (error, databaseRef) in
            guard let error = error else {
                
                let postId = newPostDatabaseRef.key
                
                GeoService.sharedInstance.create(location: postCLLocation, key: postId, success: {
                    success()
                }, failure: { (error) in
                    failure(error)
                })
                return
            }
            
            failure(error)
        }
    }
    
    func search (center: CLLocation?, radius: Double?, success: (([Post]) -> Void)!, failure: ((Error) -> Void)!) {

        
        guard let center = center else {
            failure(ServiceError.postDataError)
            return
        }
        
        guard let radius = radius, radius >= 0.0 else {
            failure(ServiceError.postGeoDataError)
            return
        }
        
        
        GeoService.sharedInstance.search(center: center, radius: radius, success: { (results) in
            
            var promises = [Promise<Post>]()
            
            if results.count > 0 {
                
                for postGeo in results {
                    promises.append(self.getPostPromise(postGeo: postGeo))
                }
                
                when(fulfilled: promises).then(execute: { (results) in
                    success(results)
                }).catch(execute: { (error) in
                    failure(error)
                })
            }
            
        }, failure: { (error) in
            failure(error)
        })
        
    }
    
    fileprivate func getPostPromise(postGeo: PostGeo) -> Promise<Post> {
        
        return Promise { fulfill, reject in

            self.postDatabaseRef.child(postGeo.id!).observeSingleEvent(of:.value, with: { (snapshot) in
                
                guard let response = snapshot.value as? NSDictionary else { return }
                do  {
                    let json = try JSONSerialization.data(withJSONObject: response, options: .prettyPrinted)
                    print(json)
                    var post = try JSONDecoder().decode(Post.self, from: json)
                    post.distance = postGeo.distance
                    
                    fulfill(post)
                    
                } catch let jsonError {
                    reject(jsonError)
                }
                
            }, withCancel: { (error) in
                reject(error)
            })
            
        }
        
    }
    
}
