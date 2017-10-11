//
//  PostService.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/10/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation
import Firebase

class PostService {
    
    static let sharedInstance = PostService()
    
    let postDatabaseRef = Database.database().reference().child("posts").childByAutoId()
    
    func create (post: Post?, success: (() -> Void)!, failure: ((Error?) -> Void)!) {
        
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
        
        let values = ["uuid": uuid, "message": message, "imageUrl": post.imageUrl as Any, "creationTimestamp": ServerValue.timestamp(), "likes": 0] as [String: Any]
        
        postDatabaseRef.updateChildValues(values) { (error, databaseRef) in
         
            guard let error = error else {
                success()
                return
            }
            
            failure(error)
        }
       
    }
    
}
