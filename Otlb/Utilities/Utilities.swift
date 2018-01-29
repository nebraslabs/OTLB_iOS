/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import Foundation
import UIKit
import SlideMenuControllerSwift
import ObjectMapper
import Firebase

class Constants: NSObject {
    static let directionsURL = "https://maps.googleapis.com/maps/api/directions/json?origin="
    static var API_KEY = ""
    static var SERVER_KEY = ""
    static var APP_NAME = ""
    override init() {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            if let infoDict = NSDictionary(contentsOfFile: path) {
                Constants.API_KEY = infoDict["GOOGLEMAPS_API_KEY"] as! String
                Constants.SERVER_KEY = infoDict["FCM_SERVER_KEY"] as! String
                Constants.APP_NAME = infoDict["CFBundleName"] as! String
            }
        }
    }
}

struct Utilities {
    
    static var User: User? {
        get {
            guard let data = UserDefaults.standard.object(forKey: "currentUser") as? Data else { return nil }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? User
        }
        set {
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: newValue!), forKey: "currentUser")
        }
    }

    static func alert(title: String?, message: String) {
        let alert = UIAlertController(title: title ?? "OTLB", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "تم", style: UIAlertActionStyle.default, handler: nil))
        UIApplication.shared.delegate!.window!!.rootViewController!.present(alert, animated: true, completion: nil)
    }
    
    static func saveUserAndLogin(_ userData: NSDictionary?, _ isClient: Bool = true) {
        guard let user = Mapper<User>().map(JSONObject: userData) else {
            return
        }
        Utilities.User = user
        login()
    }
    
    static func login(animated:Bool = true) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = Utilities.User!.serviceProvider! ? ProviderViewController.shared : CustomerViewController.shared
        let rightVC = storyboard.instantiateViewController(withIdentifier: "menuWindow")
        let slideVC = SlideMenuController(mainViewController: mainVC, rightMenuViewController: rightVC)
        slideVC.automaticallyAdjustsScrollViewInsets = false
        slideVC.changeRightViewWidth((UIScreen.main.bounds.width / 2) + 50)
        UIApplication.shared.delegate!.window!!.rootViewController = slideVC
        UIView.transition(with: UIApplication.shared.delegate!.window!!, duration: 0.5, options: animated ? .transitionFlipFromLeft : .transitionCrossDissolve, animations: {
        }, completion: { (Bool) in
        })
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    static func logout() {
        if Utilities.User!.serviceProvider! {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("driversAvailable").child(userID).removeValue()
                Database.database().reference().child("driversWorking").child(userID).removeValue()
                Database.database().reference().child("Users").child("Drivers").child(userID).child("customerRequest").removeAllObservers()
                Database.database().reference().child("Users").child("Drivers").child(userID).child("customerRequest").removeValue()
                Database.database().reference().child("Tokens").child(userID).removeValue()
            }
            let ctrl = (ProviderViewController.shared.topViewController as! ProviderViewController)
            ctrl.mapView.removeObserver(ctrl, forKeyPath: "myLocation")
        }
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.set(["ar_SA"], forKey: "AppleLanguages")
        try! Auth.auth().signOut()
        CustomerViewController.Static.instance = nil
        HistoryViewController.Static.instance = nil
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateInitialViewController()
        UIApplication.shared.delegate?.window!!.rootViewController = mainVC
        UIView.transition(with: UIApplication.shared.delegate!.window!!, duration: 0.5, options: .transitionFlipFromRight, animations: {
        }, completion: { (Bool) in
        })
    }
    
    static func sendNotification(_ token:String) {
        let parameters = ["to":token, "notification": ["body":"يوجد طلب جديد", "title":Constants.APP_NAME] ] as [String : Any]
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("key=\(Constants.SERVER_KEY)", forHTTPHeaderField: "Authorization")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            if let data = data {
                print(String.init(data: data, encoding: String.Encoding.utf8)!)
            }
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }

}
