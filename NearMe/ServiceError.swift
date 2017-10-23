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
    case postGeoDataError
    case geoServiceError
    case likeServiceDataError
    case likeServiceError
    
    var errorDescription: String? {
        switch  self {
        case .imageUploadError:
            return NSLocalizedString("Image Url Unavailable", comment: "Image Service Error" )
        case .postDataError:
            return NSLocalizedString("Post Data Error", comment: "Post Service Error" )
        case .postGeoDataError:
            return NSLocalizedString("Post Geo Data Error", comment: "Geo Service Error" )
        case .geoServiceError:
            return NSLocalizedString("Geo Service Error", comment: "Geo Service Error" )
        case .likeServiceDataError:
            return NSLocalizedString("Like Service Data Error", comment: "Like Service Error")
        case .likeServiceError:
            return NSLocalizedString("Like Service Error", comment: "Like Service Error")
        }
        
    }
}

