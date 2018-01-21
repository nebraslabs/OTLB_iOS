/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import Foundation
import UIKit

class CustomNav: UINavigationBar {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setBackgroundImage(UIImage(), for: .default)
        self.shadowImage = UIImage()
    }
}

class RoundImage: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
        layer.masksToBounds = true
    }
}

public extension UIView {
    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        
        set {
            layer.cornerRadius = newValue
        }
    }
    @IBInspectable public var BorderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable public var BorderColor: UIColor? {
        get {
            return layer.borderColor != nil ? UIColor(cgColor: layer.borderColor!) : nil
        }
        
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    @IBInspectable public var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        
        set {
            layer.shadowRadius = newValue
        }
    }
    @IBInspectable public var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        
        set {
            layer.shadowOpacity = newValue
        }
    }
    @IBInspectable public var shadowColor: UIColor? {
        get {
            return layer.shadowColor != nil ? UIColor(cgColor: layer.shadowColor!) : nil
        }
        
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    @IBInspectable public var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        
        set {
            layer.shadowOffset = newValue
        }
    }
    @IBInspectable public var zPosition: CGFloat {
        get {
            return layer.zPosition
        }
        
        set {
            layer.zPosition = newValue
        }
    }
}

public extension UIColor {
    class func hex(_ hexString: String) -> UIColor? {
        let hexInt = Int(hexString, radix: 16)
        if let hex = hexInt {
            let components = (
                R: CGFloat((hex >> 16) & 0xff) / 255,
                G: CGFloat((hex >> 08) & 0xff) / 255,
                B: CGFloat((hex >> 00) & 0xff) / 255
            )
            return UIColor(red: components.R, green: components.G, blue: components.B, alpha: 1)
        } else {
            return .black
        }
    }
}

extension UIViewController {
    open override func awakeFromNib() {
        super.awakeFromNib()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .done, target: nil, action: nil)
    }
}

import GoogleMaps
class DestinationView: UIView {
    @IBOutlet weak var txtLabel:UILabel!
    var coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var marker:GMSMarker!
}

class TypeCell: UICollectionViewCell {
    @IBOutlet var imgView:UIImageView!
    @IBOutlet var imgBg:UIView!
    @IBOutlet var textLbl:UILabel!
}

class HistoryCell: UITableViewCell {
    @IBOutlet var imgView:UIImageView!
    @IBOutlet var textLbl:UILabel!
    @IBOutlet var destLbl:UILabel!
    @IBOutlet var statusLbl:UILabel!
    @IBOutlet var dateLbl:UILabel!
}
