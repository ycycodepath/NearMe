//
//  ImageService.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/10/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation
import Firebase

class ImageService {
    
    static let sharedInstance = ImageService()
    let postImageRef = Storage.storage().reference().child("posts")

    
    func create (image: UIImage?, success: ((String?) -> Void)!, failure: ((Error?) -> Void)!) {
        
        guard let image = image else {
            failure(ServiceError.imageUploadError)
            return
        }
        
        guard let data = UIImageJPEGRepresentation(image, 0.5) else {
            failure(ServiceError.imageUploadError)
            return
        }
        
        let imageName = NSUUID().uuidString
        
        postImageRef.child(imageName).putData(data, metadata: nil) { (metadata, error) in
            
            if let error = error {
                print("Failed to upload image")
                failure(error)
                return
            } else {
                guard let imageUrl = metadata?.downloadURL()?.absoluteString else {
                    print("Failed to retrieve image url")
                    failure(ServiceError.imageUploadError)
                    return
                }
                
                success(imageUrl)
            }
            
        }
    }
    
    
}
