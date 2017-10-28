//
//  Settings.swift
//  NearMe
//
//  Created by Xiang Yu on 10/17/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import FileProvider
import UIKit

enum SortMode: Int {
    case mostRecent = 0, distance, mostLiked
}

enum SettingsSectionIdentifier : String {
    case SortBy = "Sory By"
    case Distance = "Distance"
}

typealias SettingsTable = [(sectionId: SettingsSectionIdentifier, settings: [[String:String]])]

class Settings {
    static let milesPerKM = 0.621371
    
    static let distanceChoices = [["name":"0.1 miles", "code":"\(0.1/milesPerKM)"],
                                  ["name":"0.5 miles", "code":"\(0.5/milesPerKM)"],
                                  ["name":"1 miles", "code":"\(1/milesPerKM)"],
                                  ["name":"5 miles", "code":"\(5/milesPerKM)"],
                                  ["name":"10 miles", "code":"\(10/milesPerKM)"]]
    
    static let sortByChoices = [["name":"Most Recent", "code":"0"],
                                ["name":"Distance", "code":"1"],
                                ["name":"Most Liked", "code":"2"]]
    
    static var globalSettings = loadSettingsFromUserdefault()

    static let themeColor = UIColor(red: 9/255, green: 66/255, blue: 94/255, alpha: 1.0)
    
    static let avatarNames : [String] = {
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!
        
        do {
            let items = try fm.contentsOfDirectory(atPath: "\(path)/avatars")
            
            for item in items {
                //let filename = (item as NSString).deletingPathExtension
                print("Found \(item)")
            }
            
            return items
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        
        return []
    }()
    
    var userAvatarPath : String! {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(userAvatarPath, forKey: "myAvatarImagePathInResource")
            defaults.synchronize()
        }
    }
    
    var userScreenname : String! {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(userScreenname, forKey: "myScreenname")
            defaults.synchronize()
        }
    }
    
    var userAvatarImage : UIImage? {
        let imagePath = Bundle.main.resourcePath! + userAvatarPath
        return UIImage(contentsOfFile: imagePath)
    }
    
    var sortByIndex: Int! {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(sortByIndex, forKey: "mySortByPreference")
            defaults.synchronize()
        }
    }
    
    var distanceIndex: Int! {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(distanceIndex, forKey: "myDistancePreference")
            defaults.synchronize()
        }
    }
    
    class func loadSettingsFromUserdefault() -> Settings {
        let ret = Settings()
        
        let defaults = UserDefaults.standard
        if let relativepath = defaults.object(forKey: "myAvatarImagePathInResource") as? String {
            ret.userAvatarPath = relativepath
        } else {
            ret.generateAvatar()
        }
        
        if let screenname = defaults.object(forKey: "myScreenname") as? String {
            ret.userScreenname = screenname
        } else {
            ret.userScreenname = "Ninja"
        }
        
        if let sortByIndex = defaults.object(forKey: "mySortByPreference") as? Int {
            ret.sortByIndex = sortByIndex
        } else {
            ret.sortByIndex = 0
        }
        
        if let distanceIndex = defaults.object(forKey: "myDistancePreference") as? Int {
            ret.distanceIndex = distanceIndex
        } else {
            ret.distanceIndex = 0
        }
        
        return ret
    }
    
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
    
    func generateAvatar() {
        let size = Settings.avatarNames.count
        if size > 0 {
            let number = Int(arc4random_uniform(UInt32(size)))
            userAvatarPath = "/avatars/" + Settings.avatarNames[number]
        }
    }
}
