//
//  LikeService.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/20/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation
import Firebase
import MagicalRecord

class LikeService {
    
    static let sharedInstance = LikeService()
//    let appDelegate = UIApplication.shared.delegate as! AppDelegate
//    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

//    func create (postId: String?, success: (() -> Void)!, failure: ((Error) -> Void)!) {
//
//        guard let postId = postId else {
//            failure(ServiceError.likeServiceDataError)
//            return
//        }
//
//        let like = Likes(context: context)
//        like.postId = postId
//
//        appDelegate.saveContext()
//
//        do {
//            try context.save()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nserror = error as NSError
//            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//        }
//
//    }
//
    
    func syncCoreData (postId: String?, success: ((Bool) -> Void)!, failure: ((Error) -> Void)!) {
     
        guard let postId = postId else {
            failure(ServiceError.likeServiceDataError)
            return
        }
        
        if let likeEntity = selectData(postId: postId) {
            
                likeEntity.liked = !likeEntity.liked
                likeEntity.managedObjectContext?.mr_saveToPersistentStore(completion: { (saved, error) in
                    
                    if let error = error {
                        failure(error)
                    } else if (saved) {
                        success(likeEntity.liked)
                    } else {
                        failure(ServiceError.likeServiceError)
                    }
                })
            
        } else {
            guard let likeEntity = LikeEntity.mr_createEntity() else { return }
            likeEntity.postId = postId
            likeEntity.liked = true
            likeEntity.managedObjectContext?.mr_saveToPersistentStore(completion: { (saved, error) in
                
                if let error = error {
                    failure(error)
                } else if (saved) {
                    success(true)
                } else {
                    failure(ServiceError.likeServiceError)
                }
                
            })
        }
    }
    
    func isPostLiked (postId: String) -> Bool  {

        guard let likeEntity = selectData(postId: postId) else {
            return false
        }

        if likeEntity.liked {
            return true
        }
        
        return false
    }

    fileprivate func insertData(postId: String){
        
        guard let likeEntity = LikeEntity.mr_createEntity() else { return }
        likeEntity.postId = postId
        likeEntity.liked = true
        likeEntity.managedObjectContext?.mr_saveToPersistentStoreAndWait()
    }
    

    fileprivate func updateData(postId: String, liked: Bool) -> Bool {
        
        guard let likeEntity = LikeEntity.mr_findFirst(byAttribute: "postId", withValue: postId) else { return false}
        likeEntity.liked = liked
        likeEntity.managedObjectContext?.mr_saveToPersistentStoreAndWait()
        
        return true
    }

    fileprivate func selectData (postId: String) -> LikeEntity? {
        guard let likeEntity = LikeEntity.mr_findFirst(byAttribute: "postId", withValue: postId) else { return nil}
        return likeEntity
    }
}


