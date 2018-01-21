/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import SDWebImage

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var menuTable:UITableView!
    @IBOutlet weak var userNameLabel:UILabel!
    @IBOutlet weak var phoneLabel:UILabel!
    @IBOutlet weak var userImageView:UIImageView!
    
    var images:[UIImage] = [#imageLiteral(resourceName: "home"), #imageLiteral(resourceName: "history"), #imageLiteral(resourceName: "profile"), #imageLiteral(resourceName: "about")]
    var titles:[String] = ["الصفحة الرئيسية", "الخدمات السابقة", "الملف الشخصي", "عن التطبيق"]
    var selectedIndex = IndexPath(row: 0, section: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        userNameLabel.text = Utilities.User!.name
        phoneLabel.text = Utilities.User!.phone
        userImageView.sd_setImage(with: URL.init(string: Utilities.User!.profileImageUrl ?? ""), placeholderImage: #imageLiteral(resourceName: "default"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID")!
        (cell.viewWithTag(1) as! UIImageView).image = images[indexPath.row]
        (cell.viewWithTag(2) as! UILabel).text = titles[indexPath.row]
        (cell.viewWithTag(2) as! UILabel).textColor = selectedIndex == indexPath ? UIColor.hex("586474") : UIColor.hex("989EA7")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath
        tableView.reloadData()
        
        var viewConroller:UIViewController!
        switch indexPath.row {
        case 0:
            viewConroller = Utilities.User!.serviceProvider! ? ProviderViewController.shared : CustomerViewController.shared
            break
        case 1:
            viewConroller = HistoryViewController.shared
            break
        case 2:
            viewConroller = ProfileViewController.shared
            break
        case 3:
            viewConroller = AboutViewController.shared
            break
        default:
            break
        }
        guard viewConroller != nil && slideMenuController()?.mainViewController != viewConroller else { closeRight(); return }
        slideMenuController()?.changeMainViewController(viewConroller, close: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (UIScreen.main.bounds.height - 290) / CGFloat(titles.count + 1)
    }
    
    @IBAction func logout() {
        let alert = UIAlertController(title: "الخروج", message: "هل متأكد أنك تريد الخروج؟", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "نعم", style: .destructive, handler: { (action) in
            Utilities.logout()
        }))
        alert.addAction(UIAlertAction(title: "لا", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
