//
//  Location.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/11/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation

struct Location: Codable {
    
    var latitude: Double?
    var longitude: Double?
    
    init(latitude: Double?, longitude: Double?) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
