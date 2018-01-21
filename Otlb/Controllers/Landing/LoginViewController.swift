/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import MBProgressHUD
import FirebaseAuth
import FirebaseDatabase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(_ sender: Any) {
        if self.emailTextField.text == "" || self.passwordTextField.text == "" {
            Utilities.alert(title: "خطأ", message: "من فضلك ادخل بريدك الإلكتروني وكلمة المرور")
        } else {
            self.view.endEditing(true)
            MBProgressHUD.showAdded(to: self.view, animated: true)
            Auth.auth().signIn(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (user, error) in
                if error == nil {
                    self.CheckAndSetUserData()
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    Utilities.alert(title: "خطأ", message: (error?.localizedDescription)!)
                }
            }
        }
    }
    
    func CheckAndSetUserData() {
        let userID = Auth.auth().currentUser?.uid
        Database.database().reference().child("Users").child("Customers").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                MBProgressHUD.hide(for: self.view, animated: true)
                let value = snapshot.value as? NSMutableDictionary
                value?.setObject(false, forKey: "serviceProvider" as NSCopying)
                Utilities.saveUserAndLogin(value)
            } else {
                Database.database().reference().child("Users").child("Drivers").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        let value = snapshot.value as? NSMutableDictionary
                        value?.setObject(true, forKey: "serviceProvider" as NSCopying)
                        Utilities.saveUserAndLogin(value, false)
                    }
                })
            }
        }) { error in
            MBProgressHUD.hide(for: self.view, animated: true)
            Utilities.alert(title: "خطأ", message: error.localizedDescription)
        }
    }
    
    @IBAction func openWebsite(_ sender: Any) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL.init(string: "http://www.nebrasapps.com")!, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(URL.init(string: "http://www.nebrasapps.com")!)
        }
    }
}
