/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import MBProgressHUD
import Firebase
import ObjectMapper
import SDWebImage

class ProfileViewController: UIViewController {
    struct Static { static var instance: UINavigationController? }
    class var shared: UINavigationController {
        if Static.instance == nil {
            Static.instance = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileWindow") as? UINavigationController
        }
        return Static.instance!
    }

    @IBOutlet weak var nameFld: UITextField!
    @IBOutlet weak var emailFld: UITextField!
    @IBOutlet weak var mobileFld: UITextField!
    @IBOutlet weak var profilePicture: RoundImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addRightBarButtonWithImage(#imageLiteral(resourceName: "menu"))
        profilePicture.sd_setImage(with: URL.init(string: Utilities.User!.profileImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "default"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        nameFld.text = Utilities.User!.name
        mobileFld.text = Utilities.User!.phone
        emailFld.text = Auth.auth().currentUser!.email
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveProfile(_ sender: Any) {
        guard !nameFld.text!.isEmpty && !mobileFld.text!.isEmpty else {
            Utilities.alert(title: "Error", message: "Please fill in all fields")
            return
        }
        let userID = Auth.auth().currentUser!.uid
        let type = Utilities.User!.serviceProvider! ? "Drivers" : "Customers"
        Database.database().reference().child("Users").child(type).child(userID).child("name").setValue(nameFld.text!)
        Database.database().reference().child("Users").child(type).child(userID).child("phone").setValue(mobileFld.text!)
        Utilities.User = Mapper<User>().map(JSONObject: ["name":nameFld.text!, "phone":mobileFld.text!, "serviceProvider":Utilities.User!.serviceProvider!, "profileImageUrl": Utilities.User!.profileImageUrl ?? ""])
        Utilities.alert(title: "Success", message: "Your Profile has been saved")
    }

}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBAction func changePhoto(_ sender: Any) {
        let settingsActionSheet: UIAlertController = UIAlertController(title:nil, message:nil, preferredStyle:UIAlertControllerStyle.actionSheet)
        settingsActionSheet.addAction(UIAlertAction(title:"Camera", style:UIAlertActionStyle.default, handler:{ action in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        settingsActionSheet.addAction(UIAlertAction(title:"Photo Album", style:UIAlertActionStyle.default, handler:{ action in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        settingsActionSheet.addAction(UIAlertAction(title:"Cancel", style:UIAlertActionStyle.cancel, handler:nil))
        self.present(settingsActionSheet, animated:true, completion:{
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profilePicture.image = pickedImage
            
            MBProgressHUD.showAdded(to: view, animated: true)
            let userID = Auth.auth().currentUser!.uid
            let type = Utilities.User!.serviceProvider! ? "Drivers" : "Customers"
            
            // Data in memory
            let data = UIImagePNGRepresentation(resizeImage(image: pickedImage, newWidth: 200)!)!
            
            // Create a reference to the file you want to upload
            // Points to the root reference
            let storageRef = Storage.storage().reference()
            let riversRef = storageRef.child("images/\(userID)-profile.png")
            
            // Upload the file to the path "images/rivers.jpg"
            let uploadTask = riversRef.putData(data, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    Utilities.alert(title: "Error", message: error?.localizedDescription ?? "An error occured")
                    // Uh-oh, an error occurred!
                    return
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                Database.database().reference().child("Users").child(type).child(userID).child("profileImageUrl").setValue(metadata.downloadURL()!.absoluteString)
                Utilities.User = Mapper<User>().map(JSONObject: ["name":self.nameFld.text!, "phone":self.mobileFld.text!, "serviceProvider":Utilities.User!.serviceProvider!, "profileImageUrl": metadata.downloadURL()!.absoluteString])
            }
            
            uploadTask.observe(.success) { snapshot in
                // Upload completed successfully
                MBProgressHUD.hide(for: self.view, animated: true)
                Utilities.alert(title: "Success", message: "Profile image set successfully")
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
