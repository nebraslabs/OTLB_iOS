/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import FirebaseDatabase
import FirebaseAuth
import MBProgressHUD

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    struct Static { static var instance: UINavigationController? }
    class var shared: UINavigationController {
        if Static.instance == nil {
            Static.instance = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "historyWindow") as? UINavigationController
        }
        return Static.instance!
    }
    
    var history = [History]()
    @IBOutlet weak var historyTable:UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addRightBarButtonWithImage(#imageLiteral(resourceName: "menu"))
        historyTable.tableFooterView = UIView()
        MBProgressHUD.showAdded(to: view, animated: true)
        
        Database.database().reference().child("history").observe(.value, with: { (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? NSDictionary{
                MBProgressHUD.hide(for: self.view, animated: true)
                self.history.removeAll()
                for key in value.allKeys {
                    if let item = History(JSON: value[key] as! [String: Any]),
                        (Utilities.User!.serviceProvider! && item.driver == Auth.auth().currentUser!.uid) ||
                            (!Utilities.User!.serviceProvider! && item.customer == Auth.auth().currentUser!.uid) {
                            self.history.append(item)
                    }
                }
                self.history.sort(by: { (h1, h2) -> Bool in
                    return h1.timestamp! < h2.timestamp!
                })
                self.historyTable.reloadSections(IndexSet.init(integer: 0), with: .automatic)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID") as! HistoryCell
        let object = history[indexPath.row]
        cell.imgView.image = UIImage(named: "_\(object.service ?? "1")")
        cell.textLbl.text = object.pickup
        cell.destLbl.text = object.destination
        cell.statusLbl.text = object.status?.capitalized
        cell.statusLbl.textColor = object.status == "Accepted" || object.status == "Completed" || object.status == "PickUp Done" ? UIColor.hex("00A310") : UIColor.hex("AA0C00")
        let date = Date.init(timeIntervalSince1970: object.timestamp ?? Date().timeIntervalSince1970)
        let df = DateFormatter(); df.dateFormat = "hh:mm a"; df.locale = Locale(identifier: "ar_SA")
        cell.dateLbl.text = df.string(from: date)
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

