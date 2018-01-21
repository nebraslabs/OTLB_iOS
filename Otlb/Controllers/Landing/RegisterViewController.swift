/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import SlideMenuControllerSwift
import FirebaseAuth
import MBProgressHUD
import FirebaseDatabase

class RegisterViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var customerButton: UIButton!
    @IBOutlet weak var serviceProviderButton: UIButton!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var isCustomer = true
    var selectedTypes = [IndexPath]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 14
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellID", for: indexPath) as! TypeCell
        cell.textLbl.textColor = UIColor.hex("9aa0a8")
        cell.textLbl.text = ["تاكسي", "توصيل طلبات", "سطحة", "كهرباء", "سباكة", "عمالة نزلية", "وقود", "كفرات السيارة", "تغيير زيت", "غسيل السيارة", "بطارية السيارة", "قفل السيارة", "صيانة سيارة", "مياه معدنية"][indexPath.row]
        cell.imgView.image = UIImage(named: "_\(indexPath.row + 1)")
        cell.imgBg.alpha = selectedTypes.contains(indexPath) ? 0.0 : 0.5
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedTypes.contains(indexPath) {
            selectedTypes.remove(at: selectedTypes.index(of: indexPath)!)
        } else {
            selectedTypes.append(indexPath)
        }
        collectionView.reloadItems(at: [indexPath])
    }

    @IBAction func isCustomer(_ sender: Any) {
        heightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.customerButton.setTitleColor(UIColor.white, for: .normal)
            self.customerButton.backgroundColor = UIColor.hex("084265")
            self.serviceProviderButton.setTitleColor(UIColor.hex("084265"), for: .normal)
            self.serviceProviderButton.backgroundColor = UIColor.clear
            self.view.layoutIfNeeded()
        }
        isCustomer = true
    }
    
    @IBAction func isServiceProvider(_ sender: Any) {
        heightConstraint.constant = 128
        UIView.animate(withDuration: 0.3) {
            self.customerButton.setTitleColor(UIColor.hex("084265"), for: .normal)
            self.customerButton.backgroundColor = UIColor.clear
            self.serviceProviderButton.setTitleColor(UIColor.white, for: .normal)
            self.serviceProviderButton.backgroundColor = UIColor.hex("084265")
            self.view.layoutIfNeeded()
        }
        isCustomer = false
    }

    @IBAction func register(_ sender: Any) {
        if self.emailTextField.text == "" || self.passwordTextField.text == "" {
            Utilities.alert(title: "Error", message: "Please enter an email and password.")
        } else {
            self.view.endEditing(true)
            MBProgressHUD.showAdded(to: self.view, animated: true)
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                if let user = user, error == nil {
                    print(user)
                    var userModel:[String: Any] = ["name": self.nameTextField.text!,"phone": self.mobileTextField.text!,"email": self.emailTextField.text!, "profileImageUrl": ""]
                    if self.isCustomer {
                        Database.database().reference().child("Users").child("Customers").child(user.uid).setValue(userModel)
                        userModel["serviceProvider"] = false
                    } else {
                        var services = [String]()
                        for type in self.selectedTypes {
                            services.append("\(type.row + 1)")
                        }
                        userModel["service"] = "\(services.joined(separator: ","))"
                        Database.database().reference().child("Users").child("Drivers").child(user.uid).setValue(userModel)
                        userModel["serviceProvider"] = true
                    }
                    Utilities.saveUserAndLogin(userModel as NSDictionary)
                } else {
                    Utilities.alert(title: "Error", message: (error?.localizedDescription)!)
                }
            }
        }
    }
    
}

