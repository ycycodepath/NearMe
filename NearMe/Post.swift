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
    let message: String?
    let imageUrl: String?
    let creationTimestamp: Date?
    let likes: Int?
    
}
