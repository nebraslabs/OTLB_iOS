/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import IQKeyboardManager
import SlideMenuControllerSwift
import GoogleMaps
import GooglePlaces
import Firebase
import Fabric
import Crashlytics
import GooglePlacePicker
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Initialize Constants
        _ = Constants()
        
        // Keyboard Manager Support
        IQKeyboardManager.shared().isEnabled = true
        
        // SlideMenu Options
        SlideMenuOptions.hideStatusBar = false
        SlideMenuOptions.simultaneousGestureRecognizers = false
        
        // Google Maps and Google Places API Keys
        GMSServices.provideAPIKey(Constants.API_KEY)
        GMSPlacesClient.provideAPIKey(Constants.API_KEY)
        
        // Customize Google Place Picker Colors
        let navBar = (UINavigationBar.appearance(whenContainedInInstancesOf: [GMSPlacePickerViewController.self]))
        navBar.barTintColor = UIColor.hex("013756")
        navBar.tintColor = .white
        navBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navBar.isTranslucent = false
        
        // Firebase Configuration
        FirebaseApp.configure()
        
        // Crashlytics Initiations
        Fabric.with([Crashlytics.self])
        
        // Check if user already logged-in
        if Utilities.User != nil {
            Utilities.login(animated: false)
        }
        
        // Register device for Push Notifications
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        // Change Maps and General App Language to Arabic
        UserDefaults.standard.set(["ar_SA"], forKey: "AppleLanguages")

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        if let user = Auth.auth().currentUser {
            print("Push Token:\(Messaging.messaging().fcmToken!)")
            Database.database().reference().child("Tokens").child(user.uid).child("token").setValue(Messaging.messaging().fcmToken!)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print(userInfo)
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
        if let userID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("driversAvailable").child(userID).removeValue()
        }
    }


}

