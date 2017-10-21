//
//  Settings.swift
//  NearMe
//
//  Created by Xiang Yu on 10/17/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

enum SortMode: Int {
    case mostRecent = 0, distance, mostLiked
}

enum SettingsSectionIdentifier : String {
    case SortBy = "Sory By"
    case Distance = "Distance"
}

typealias SettingsTable = [(sectionId: SettingsSectionIdentifier, settings: [[String:String]])]

struct Settings {
    static let milesPerKiloMeter = 0.621371
    
    static let distanceChoices = [["name":"Auto", "code":"0"],
                                  ["name":"0.5 miles", "code":"\(0.5/milesPerKiloMeter)"],
                                  ["name":"1 miles", "code":"\(1/milesPerKiloMeter)"],
                                  ["name":"5 miles", "code":"\(5/milesPerKiloMeter)"],
                                  ["name":"10 miles", "code":"\(10/milesPerKiloMeter)"],
                                  ["name":"25 miles", "code":"\(25/milesPerKiloMeter)"]]
    
    static let sortByChoices = [["name":"Most Recent", "code":"0"],
                                ["name":"Distance", "code":"1"],
                                ["name":"Most Liked", "code":"2"]]

    
    var sortBy: SortMode?
    var distance: Double?
}
