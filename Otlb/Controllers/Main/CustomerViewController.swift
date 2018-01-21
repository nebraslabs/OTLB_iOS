/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import GoogleMaps
import GooglePlacePicker
import MBProgressHUD
import Firebase
import GeoFire
import ObjectMapper
import SDWebImage

protocol PickLocationDelegate {
    func pickedLocation(didPick location: CLLocationCoordinate2D, address: GMSAddress?)
}

class CustomerViewController: UIViewController, GMSPlacePickerViewControllerDelegate, PickLocationDelegate {
    struct Static { static var instance: UINavigationController? }
    static var shared: UINavigationController {
        if Static.instance == nil {
            Static.instance = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainWindow") as? UINavigationController
        }
        return Static.instance!
    }
    
    @IBOutlet weak var servicesCollection:UICollectionView!
    @IBOutlet weak var pickView:DestinationView!
    @IBOutlet weak var dropView:DestinationView!
    var selectedType = IndexPath(item: 0, section: 0)
    @IBOutlet weak var mapView:GMSMapView!
    var currentMode:DestinationView!
    var didSetLocation:Bool = false
    @IBOutlet weak var requestSpinner:UIActivityIndicatorView!
    @IBOutlet weak var requestButton:UIButton!
    @IBOutlet weak var requestButtonHeight:NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint:NSLayoutConstraint!
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var phoneLabel:UILabel!
    @IBOutlet weak var durationLabel:UILabel!
    @IBOutlet weak var userImage: RoundImage!
    @IBOutlet weak var servicesConstraint:NSLayoutConstraint!
    var polyline:GMSPolyline!
    var nearbyQuery:GFCircleQuery?
    var driversQueue:DriversQueue!
    var queryTimer:Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addRightBarButtonWithImage(#imageLiteral(resourceName: "menu"))
        currentMode = pickView
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.addObserver(self, forKeyPath: "myLocation", options: .new, context: nil)
        requestButtonHeight.constant = 0
        self.bottomConstraint.constant = -160
        initDrivers()
        checkRequest()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        mapView.removeObserver(self, forKeyPath: "myLocation")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "myLocation" && !didSetLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 16.0)
            didSetLocation = true
        }
    }

    func addMarkerOnMap(_ targetView:DestinationView) {
        OperationQueue.main.addOperation({
            DispatchQueue.main.async {
                if targetView.marker == nil {
                    targetView.marker = GMSMarker(position: targetView.coordinate)
                    if targetView == self.pickView {
                        targetView.marker.icon = GMSMarker.markerImage(with: .green)
                    }
                } else {
                    targetView.marker.position = targetView.coordinate
                }
                targetView.marker.map = self.mapView
                targetView.marker.snippet = targetView.txtLabel.text
                self.mapView.camera = GMSCameraPosition.camera(withTarget: targetView.coordinate, zoom: 16.0)
                if self.selectedType.row > 2 || (self.selectedType.row <= 2 && self.dropView.coordinate.latitude > 0) {
                    self.requestButtonHeight.constant = 60
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.3, animations: {
                            self.view.layoutIfNeeded()
                        })
                    }
                    if self.polyline != nil {
                        self.polyline.map = nil
                    }
                    self.drawPath()
                }
            }
        })
    }

    func pickedLocation(didPick location: CLLocationCoordinate2D, address: GMSAddress?) {
        if let address = address, let lines = address.lines {
            pickView.txtLabel.text = lines.joined(separator: ",")
            pickView.coordinate = address.coordinate
            self.addMarkerOnMap(self.pickView)
        }
    }
    
    func placePicker(_ viewController: GMSPlacePickerViewController, didPick place: GMSPlace) {
        viewController.dismiss(animated: true) {
            self.dropView.txtLabel.text = place.formattedAddress ?? place.name
            self.dropView.coordinate = place.coordinate
            self.addMarkerOnMap(self.dropView)
        }
    }
    
    func placePickerDidCancel(_ viewController: GMSPlacePickerViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func checkRequest() {
        let userID = Auth.auth().currentUser!.uid
        DB.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() && snapshot.hasChild("customerRequest") {
                DB.child("customerRequest").queryOrderedByKey().queryEqual(toValue: userID).observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists() {
                        print("Found request")
                        Drivers.queryOrdered(byChild: "customerRequest/customerRideId").queryEqual(toValue: userID).observeSingleEvent(of: .value, with: { (snapshot) in
                            if snapshot.exists(), let value = snapshot.value as? NSDictionary, let driver = value.allKeys.first as? String, let request = Mapper<Request>().map(JSONObject: (value[driver] as! NSDictionary)["customerRequest"]) {
                                
                                self.driversQueue.active = driver
                                
                                self.pickView.txtLabel.text = request.pickup
                                self.pickView.coordinate = CLLocationCoordinate2DMake(request.pickupLat!, request.pickupLng!)
                                self.addMarkerOnMap(self.pickView)
                                
                                self.dropView.txtLabel.text = request.destination
                                self.dropView.coordinate = CLLocationCoordinate2DMake(request.destinationLat!, request.destinationLng!)
                                self.addMarkerOnMap(self.dropView)
                                
                                self.observerRequest()
                            }
                        }, withCancel: nil)
                    }
                }, withCancel: nil)
            }
        }, withCancel: nil)
    }
    
    @IBAction func makeRequest(_ sender: UIButton) {
        let userID = Auth.auth().currentUser!.uid
        let requestFire = GeoFire(firebaseRef: DB.child("customerRequest"))
        requestFire?.setLocation(CLLocation(latitude: pickView.coordinate.latitude, longitude: pickView.coordinate.longitude), forKey: userID)
        
        requestUI()
        getNearbyDrivers()
    }
    
    func createRequest() -> [String: Any] {
        let userID = Auth.auth().currentUser!.uid
        return [
            "customerRideId":userID,
            "status":"Pending",
            "service":self.selectedType.row + 1,
            "pickup":self.pickView.txtLabel.text!,
            "pickupLat":self.pickView.coordinate.latitude,
            "pickupLng":self.pickView.coordinate.longitude,
            "destination":self.dropView.txtLabel.text!,
            "destinationLat":self.dropView.coordinate.latitude,
            "destinationLng":self.dropView.coordinate.longitude
        ]
    }
    
    func getNearbyDrivers() {
        nearbyQuery?.removeAllObservers()
        let geoFire = GeoFire(firebaseRef: DB.child("driversAvailable"))
        let center = CLLocation(latitude: pickView.coordinate.latitude, longitude: pickView.coordinate.longitude)
        nearbyQuery = geoFire?.query(at: center, withRadius: 10)
        nearbyQuery?.observe(.keyEntered, with: { (key, location) in
            guard let driverID = key, !self.driversQueue.cancelled.contains(driverID) else { return }
            self.getNextDriver(driverID)
        })
    }
    
    func getNextDriver(_ key: String) {
        if driversQueue.active.isEmpty && driversQueue.queued.count == 0 {
            driversQueue.active = key
            observeDriver()
        } else if driversQueue.active != key {
            if !driversQueue.queued.contains(key) {
                driversQueue.queued.append(key)
            } else {
                driversQueue.active = key
                driversQueue.queued.remove(at: driversQueue.queued.index(of: key)!)
                observeDriver()
            }
        }
    }
    
    func observeDriver() {
        Drivers.child(driversQueue.active).observeSingleEvent(of: .value, with: { (_snapshot) in
            if _snapshot.exists(), let value = _snapshot.value as? NSDictionary, let services = value["service"] as? String, services.contains("\(self.selectedType.row + 1)") {
                DB.child("Tokens").child(self.driversQueue.active).observeSingleEvent(of: .value) { (snapshot) in
                    if snapshot.exists(), let value = snapshot.value as? NSDictionary, let token = value["token"] as? String {
                        Utilities.sendNotification(token)
                    }
                }
                let driver = Drivers.child(self.driversQueue.active)
                driver.child("customerRequest").setValue(self.createRequest())
                self.observerRequest()
            } else {
                self.gotoNextDriver()
            }
        }, withCancel: nil)
    }
    
    func observerRequest() {
        let driver = Drivers.child(driversQueue.active)
        driver.child("customerRequest").observe(.value) { (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? NSDictionary, let request = Mapper<Request>().map(JSONObject: value) {
                switch request.status! {
                case "accepted":
                    self.queryTimer?.invalidate()
                    self.nearbyQuery?.removeAllObservers()
                    self.showTripUI()
                    driver.observeSingleEvent(of: .value, with: { (snapshot) in
                        guard let _value = snapshot.value as? NSDictionary else { return }
                        self.nameLabel.text = _value["name"] as? String
                        self.phoneLabel.text = _value["phone"] as? String
                        self.userImage.sd_setImage(with: URL.init(string: _value["profileImageUrl"] as! String), placeholderImage: #imageLiteral(resourceName: "default"))
                        if let duration = value["duration"] as? String, let distance = value["distance"] as? String {
                            self.durationLabel.text = "\(distance) - \(duration)"
                        }
                    })
                    break
                case "PickUp Done":
                    self.nearbyQuery?.removeAllObservers()
                    self.showTripUI()
                    driver.observeSingleEvent(of: .value, with: { (snapshot) in
                        guard let _value = snapshot.value as? NSDictionary else { return }
                        self.nameLabel.text = _value["name"] as? String
                        self.phoneLabel.text = _value["phone"] as? String
                        self.userImage.sd_setImage(with: URL.init(string: _value["profileImageUrl"] as! String), placeholderImage: #imageLiteral(resourceName: "default"))
                        if let duration = value["duration"] as? String, let distance = value["distance"] as? String {
                            self.durationLabel.text = "\(distance) - \(duration)"
                        }
                    })
                    self.onboardOrFinishedUI()
                    break
                case "Completed":
                    Utilities.alert(title: "نجاح", message: "تم تقديم الخدمة بنجاح 🙏")
                    self.doResetOrder()
                    break
                default:
                    break
                }
            } else {
                self.gotoNextDriver()
            }
        }
    }
    
    func gotoNextDriver() {
        self.driversQueue.cancelled.append(self.driversQueue.active)
        if self.driversQueue.queued.count > 0 {
            Drivers.child(self.driversQueue.active).child("customerRequest").removeAllObservers()
            self.getNearbyDrivers()
        } else {
            self.cancelRequest()
            Utilities.alert(title: "لا يوجد مقدمين خدمة", message: "لا يوجد مقدمين خدمة بالقرب من موقعك")
        }
    }
    
    @objc func cancelRequest() {
        onboardOrFinishedUI(true)
        hideTripUI()

        nearbyQuery?.removeAllObservers()
        
        if let active = driversQueue.active, !active.isEmpty {
            Drivers.child(driversQueue.active).child("customerRequest").child("status").setValue("Cancelled")
            Drivers.child(driversQueue.active).child("customerRequest").removeAllObservers()
            Drivers.child(driversQueue.active).child("customerRequest").removeValue()
        }

        self.initDrivers()
    }
}

extension CustomerViewController {
    func initDrivers() {
        driversQueue = Mapper<DriversQueue>().map(JSON: ["active":"", "queued":[String](), "cancelled":[String]()])!
    }
    
    func requestUI() {
        requestSpinner.startAnimating()
        requestButton.backgroundColor = UIColor.hex("AA0C00")
        requestButton.setTitle("جاري الطلب... اضغط للالغاء", for: .normal)
        requestButton.removeTarget(self, action: #selector(makeRequest(_:)), for: .touchUpInside)
        requestButton.addTarget(self, action: #selector(cancelRequest), for: .touchUpInside)
        if requestButtonHeight.constant < 60 {
            requestButtonHeight.constant = 60
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func onboardOrFinishedUI(_ cancelled: Bool = false) {
        requestSpinner.stopAnimating()
        requestButton.backgroundColor = UIColor.hex("013756")
        requestButton.setTitle(cancelled ? "اطلب الآن" : "علي متن الرحلة", for: .normal)
        requestButton.removeTarget(self, action: #selector(self.cancelRequest), for: .touchUpInside)
        requestButton.addTarget(self, action: #selector(self.makeRequest(_:)), for: .touchUpInside)
        requestButton.isEnabled = cancelled
        userImage.image = #imageLiteral(resourceName: "default")
        if requestButtonHeight.constant < 60 {
            requestButtonHeight.constant = 60
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func showTripUI() {
        requestButtonHeight.constant = 60
        bottomConstraint.constant = 80
        servicesConstraint.constant = 0
        let padding:CGFloat = 170
        UIView.animate(withDuration: 0.3, animations: {
            self.mapView.padding = UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0)
            self.view.layoutIfNeeded()
        })
    }
    
    func hideTripUI() {
        if pickView.coordinate.latitude == 0 && dropView.coordinate.longitude == 0 {
            requestButtonHeight.constant = 0
        }
        bottomConstraint.constant = -160
        servicesConstraint.constant = 80
        UIView.animate(withDuration: 0.3, animations: {
            self.mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func togglePickAndDrop(_ sender: UIButton) {
        var topConstraints = [String]()
        var upperSideConstraints = [String]()
        var lowerSideConstraints = [String]()
        
        if sender.superview == currentMode {
            switch currentMode {
            case pickView:
                let locationPicker = storyboard?.instantiateViewController(withIdentifier: "pickWindow") as! PickLocationViewController
                locationPicker.delegate = self
                present(locationPicker, animated: true, completion: nil)
                break
                
            case dropView:
                let config = GMSPlacePickerConfig(viewport: nil)
                let placePicker = GMSPlacePickerViewController(config: config)
                placePicker.delegate = self
                present(placePicker, animated: true, completion: nil)
                break
                
            default:
                break
            }
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            if sender.superview == self.pickView {
                
                topConstraints = ["dropTop", "pickTop"]
                upperSideConstraints = ["dropLeft", "dropRight"]
                lowerSideConstraints = ["pickLeft", "pickRight"]
                
                self.currentMode = self.pickView
            } else if sender.superview == self.dropView {
                
                topConstraints = ["pickTop", "dropTop"]
                upperSideConstraints = ["pickLeft", "pickRight"]
                lowerSideConstraints = ["dropLeft", "dropRight"]
                
                self.currentMode = self.dropView
            }
            
            self.view.constraints.first{ $0.identifier == topConstraints[0] }?.constant = 50
            self.view.constraints.first{ $0.identifier == topConstraints[1] }?.constant = 20
            
            self.view.constraints.forEach{ guard let _id = $0.identifier else { return }; if upperSideConstraints.contains(_id) { $0.constant = 30 } }
            self.view.constraints.forEach{ guard let _id = $0.identifier else { return }; if lowerSideConstraints.contains(_id) { $0.constant = 16 } }
            
            self.view.layoutIfNeeded()
            self.view.bringSubview(toFront: self.currentMode!)
        }
    }
    
    func doResetOrder() {
        DispatchQueue.main.async {
            self.cancelRequest()

            self.mapView.clear()
            if self.currentMode != self.pickView {
                self.togglePickAndDrop(self.pickView.subviews.last as! UIButton)
            }
            self.pickView.txtLabel.text = "مكان الانطلاق"
            self.dropView.txtLabel.text = "مكان الوصول"
            self.pickView.coordinate = CLLocationCoordinate2DMake(0, 0)
            self.dropView.coordinate = CLLocationCoordinate2DMake(0, 0)
            self.didSetLocation = false
            self.requestButtonHeight.constant = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func drawPath() {
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(pickView.coordinate.latitude),\(pickView.coordinate.longitude)&destination=\(dropView.coordinate.latitude),\(dropView.coordinate.longitude)"
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: {
            (data, response, error) in
            if(error == nil) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                    let routes = json["routes"] as! NSArray
                    OperationQueue.main.addOperation({
                        for route in routes {
                            let routeOverviewPolyline:NSDictionary = (route as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
                            let points = routeOverviewPolyline.object(forKey: "points")
                            let path = GMSPath.init(fromEncodedPath: points! as! String)
                            self.polyline = GMSPolyline.init(path: path)
                            self.polyline.strokeWidth = 3
                            self.polyline.strokeColor = UIColor.hex("013756")!
                            let bounds = GMSCoordinateBounds(path: path!)
                            self.mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 120.0))
                            self.polyline.geodesic = true
                            self.polyline.map = self.mapView
                        }
                    })
                } catch let error as NSError{
                    print("error:\(error)")
                }
            }
        }).resume()
    }

}

extension CustomerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 14
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CellID", for: indexPath) as! TypeCell
        cell.textLbl.textColor = UIColor.hex("9aa0a8")
        cell.textLbl.text = ["تاكسي", "توصيل طلبات", "سطحة", "كهرباء", "سباكة", "عمالة نزلية", "وقود", "كفرات السيارة", "تغيير زيت", "غسيل السيارة", "بطارية السيارة", "قفل السيارة", "صيانة سيارة", "مياه معدنية"][indexPath.row]
        cell.imgView.image = UIImage(named: "_\(indexPath.row + 1)")
        cell.imgBg.alpha = selectedType == indexPath ? 0.0 : 0.5
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard selectedType != indexPath && !requestSpinner.isAnimating else {
            return
        }
        let currentType = selectedType
        selectedType = indexPath
        collectionView.reloadItems(at: [currentType])
        collectionView.reloadItems(at: [indexPath])
        
        if indexPath.row > 2 {
            if currentMode != pickView {
                togglePickAndDrop(pickView.subviews[2] as! UIButton)
            }
            dropView.isHidden = true
        } else {
            dropView.isHidden = false
        }
        doResetOrder()
    }
    
}

class PickLocationViewController: UIViewController, GMSMapViewDelegate {
    var delegate:PickLocationDelegate?
    @IBOutlet weak var mapView:GMSMapView!
    var marker:GMSMarker!
    var didSetLocation:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        mapView.addObserver(self, forKeyPath: "myLocation", options: .new, context: nil)
    }
    
    deinit {
        mapView.removeObserver(self, forKeyPath: "myLocation")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "myLocation" && !didSetLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 16.0)
            marker = GMSMarker(position: myLocation.coordinate)
            marker.map = mapView
            marker.icon = GMSMarker.markerImage(with: .green)
            didSetLocation = true
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        marker.position = coordinate
        mapView.animate(to: GMSCameraPosition.camera(withTarget: coordinate, zoom: mapView.camera.zoom))
    }
    
    @IBAction func pickedLocation(_ sender: UIBarButtonItem) {
        MBProgressHUD.showAdded(to: view, animated: true)
        GMSGeocoder().reverseGeocodeCoordinate(marker.position) { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.dismiss(animated: true) {
                self.delegate?.pickedLocation(didPick: self.marker.position, address: response?.firstResult())
            }
        }
    }
    
    @IBAction func dismissMe() {
        self.dismiss(animated: true, completion: nil)
    }
}
