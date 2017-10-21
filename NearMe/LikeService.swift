//
//  LikeService.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/20/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation
import Firebase
import CoreData

class LikeService {
    
    static let sharedInstance = LikeService()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    func create (postId: String?, success: (() -> Void)!, failure: ((Error) -> Void)!) {
        
        guard let postId = postId else {
            failure(ServiceError.likeServiceDataError)
            return
        }
        
        let like = Likes(context: context)
        like.postId = postId
        
        appDelegate.saveContext()
        
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    
    }
    
    func isPostLiked (postId: String?) -> Bool  {
    
        guard let postId = postId else {
            return false
        }
        
        return true
    }
    
    fileprivate func getLikeRecord() {
        
    }
}


