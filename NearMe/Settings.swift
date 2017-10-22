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
    static let milesPerKM = 0.621371
    
    static let distanceChoices = [["name":"0.1 miles", "code":"\(0.1/milesPerKM)"],
                                  ["name":"0.5 miles", "code":"\(0.5/milesPerKM)"],
                                  ["name":"1 miles", "code":"\(1/milesPerKM)"],
                                  ["name":"5 miles", "code":"\(5/milesPerKM)"],
                                  ["name":"10 miles", "code":"\(10/milesPerKM)"]]
    
    static let sortByChoices = [["name":"Most Recent", "code":"0"],
                                ["name":"Distance", "code":"1"],
                                ["name":"Most Liked", "code":"2"]]
    
    static var globalSettings = Settings(sortByIndex: 0, distanceIndex: 0)
    
    var sortByIndex: Int
    var distanceIndex: Int
    
    var sortBy: SortMode {
        var ret:SortMode?
        if let strSort = Settings.sortByChoices[sortByIndex]["code"], let intSort = Int(strSort) {
            ret = SortMode(rawValue: intSort)
        }
        
        return ret ?? SortMode.mostRecent
    }
    
    var distance: Double {
        var ret:Double?
        if let strDistance = Settings.distanceChoices[distanceIndex]["code"] {
            ret = Double(strDistance)
        }
        
        return ret ?? 0.1/Settings.milesPerKM
    }
}
