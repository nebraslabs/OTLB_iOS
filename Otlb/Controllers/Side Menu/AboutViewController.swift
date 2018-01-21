/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit

class AboutViewController: UIViewController {
    struct Static { static var instance: UINavigationController? }
    class var shared: UINavigationController {
        if Static.instance == nil {
            Static.instance = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "aboutWindow") as? UINavigationController
        }
        return Static.instance!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addRightBarButtonWithImage(#imageLiteral(resourceName: "menu"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openWebsite(_ sender: Any) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL.init(string: "http://www.nebrasapps.com")!, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
            UIApplication.shared.openURL(URL.init(string: "http://www.nebrasapps.com")!)
        }
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
