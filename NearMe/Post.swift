//
//  Posts.swift
//  NearMe
//
//  Created by Liqiang Ye on 10/10/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import Foundation

struct Post: Codable {
    
    var id: String?
    var uuid: String?
    var message: String?
    var imageUrl: String?
    var creationTimestamp: Date?
    var likes: Int?
    var location: Location?
    var screen_name: String?
    var place: String?
    var address: String?
    var distance: Double?
    
    init(uuid: String?, message: String?, location: Location?, screen_name: String?, place: String?, address: String?) {
        self.uuid = uuid
        self.message = message
        self.location = location
        self.screen_name = screen_name
        self.place = place
        self.address = address
    }
}
