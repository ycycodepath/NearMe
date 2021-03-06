//
//  AppDelegate.swift
//  NearMe
//
//  Created by Xiang Yu on 10/6/17.
//  Copyright © 2017 ycyteam. All rights reserved.
//

import UIKit
import Firebase
import SwiftyBeaver
import GooglePlaces
import GoogleMaps
import CoreData
import MagicalRecord
import ESTabBarController_swift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootTabBarController: ESTabBarController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        let console = ConsoleDestination()
        SwiftyBeaver.addDestination(console)

        //core data: magical record set up
        MagicalRecord.setupCoreDataStack(withAutoMigratingSqliteStoreNamed: "NearMe.sql")

        
        GMSPlacesClient.provideAPIKey("AIzaSyBPZgNeZOx1PSni5OalI1zYo56TTWcLTKE")
        GMSServices.provideAPIKey("AIzaSyDLpnvclx1PpHuluGw8GBZ2eCYd3cAWMII")
        
        rootTabBarController = customTabBarController()
        window?.rootViewController = rootTabBarController

        let navigationBarAppearace = UINavigationBar.appearance()
        
        navigationBarAppearace.barStyle = .black
        navigationBarAppearace.tintColor = UIColor.white
        navigationBarAppearace.barTintColor = Settings.themeColor
        navigationBarAppearace.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        
        navigationBarAppearace.isTranslucent = true
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]

        //let barButtonItemAppearance = UIBarButtonItem.appearance()
        //barButtonItemAppearance.tintColor = UIColor.white
        sleep(1)
        return true
    }
    
    func customTabBarController() -> ESTabBarController {
        let tabBarController = ESTabBarController()
        tabBarController.tabBar.shadowImage = UIImage(named: "transparent")
        tabBarController.tabBar.backgroundImage = UIImage(named: "background_dark")
        
        let homeStortboard = UIStoryboard(name: "Home", bundle: nil)
        let homeNavController = homeStortboard.instantiateViewController(withIdentifier: "HomeNavigationController") as! UINavigationController

        let composeStortboard = UIStoryboard(name: "Compose", bundle: nil)
        let composeNavController = composeStortboard.instantiateViewController(withIdentifier: "ComposeNavigationController") as! UINavigationController

        let settingsStortboard = UIStoryboard(name: "Settings", bundle: nil)
        let settingsNavController = settingsStortboard.instantiateViewController(withIdentifier: "SettingsNavigationController") as! UINavigationController

        
        let v1 = homeNavController
        let v2 = composeNavController
        let v3 = settingsNavController
        
        v1.tabBarItem = ESTabBarItem.init(ExampleIrregularityBasicContentView(), title: nil, image: UIImage(named: "home"), selectedImage: UIImage(named: "home_1"))
        v2.tabBarItem = ESTabBarItem.init(ExampleIrregularityContentView(), title: nil, image: UIImage(named: "photo_verybig"), selectedImage: UIImage(named: "photo_verybig"))
        v3.tabBarItem = ESTabBarItem.init(ExampleIrregularityBasicContentView(), title: nil, image: UIImage(named: "me"), selectedImage: UIImage(named: "me_1"))
        
        tabBarController.viewControllers = [v1, v2, v3]

        tabBarController.shouldHijackHandler = {
            tabbarController, viewController, index in
            if index == 1 {
                return true
            }
            return false
        }
        tabBarController.didHijackHandler = {
            tabbarController, viewController, index in
            
            let composeStortboard = UIStoryboard(name: "Compose", bundle: nil)
            let composeNavController = composeStortboard.instantiateViewController(withIdentifier: "ComposeNavigationController") as! UINavigationController
            
            if let composeViewController = composeNavController.viewControllers.first as? ComposeViewController, let homeViewController = homeNavController.viewControllers.first as? HomeViewController {
                composeViewController.delegate = homeViewController
            }
            
            tabbarController
                .present(composeNavController, animated: true, completion: nil)
            
        }
        
        return tabBarController
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "NearMe")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


}

