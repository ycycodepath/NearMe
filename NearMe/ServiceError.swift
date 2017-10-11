//
//  ServiceError.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/10/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation

enum ServiceError: LocalizedError {
    
    case imageUploadError
    case postDataError
    
    var errorDescription: String? {
        switch  self {
        case .imageUploadError:
            return NSLocalizedString("Image Url Unavailable", comment: "Image Service Error" )
        case .postDataError:
            return NSLocalizedString("Post Data Error", comment: "Post Service Error" )
        }
    }
}

