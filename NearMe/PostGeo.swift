//
//  PostGeo.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/13/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation

struct PostGeo {
    
    var id: String?
    var distance: String?
    
    init(id: String?, distance: String?) {
        self.id = id
        self.distance = distance
    }
    
}
