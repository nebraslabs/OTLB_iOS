/**
 * ============================================================================
 *                                       🤓
 *              Copyright (c) 12/01/2018 - NebrasApps All Rights Reserved
 *                    www.nebrasapps.com - Hi@nebrasapps.com
 * ============================================================================
 */

import UIKit
import GoogleMaps
import GeoFire
import FirebaseDatabase
import FirebaseAuth
import SDWebImage
import ObjectMapper

var DB = Database.database().reference()
var Drivers = DB.child("Users").child("Drivers")
var Customers = DB.child("Users").child("Customers")

class ProviderViewController: UIViewController {
    struct Static { static var instance: UINavigationController? }
    static var shared: UINavigationController {
        if Static.instance == nil {
            Static.instance = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "providerWindow") as? UINavigationController
        }
        return Static.instance!
    }
    
    @IBOutlet weak var mapView:GMSMapView!
    var myLocation:CLLocation!
    var requestsQuery:NSKeyValueObservation!
    @IBOutlet weak var topConstraint:NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint:NSLayoutConstraint!
    @IBOutlet weak var distanceLbl:UILabel!
    @IBOutlet weak var durationLbl:UILabel!
    @IBOutlet weak var userImage: RoundImage!
    @IBOutlet weak var actionButton:UIButton!
    @IBOutlet weak var cancelButton:UIButton!
    @IBOutlet weak var workingSwitch:UISwitch!
    var distance:String! = "غير معلوم"
    var duration:String! = "غير معلوم"
    var didSetLocation:Bool = false
    var incomingRequest:Bool! = false {
        didSet {
            if incomingRequest {
                didSetLocation = true
                showStatus()
            } else {
                didSetLocation = false
                hideStatus(true)
            }
        }
    }
    var isWorking:Bool = false
    var userID:String!
    
    var request:DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        addRightBarButtonWithImage(#imageLiteral(resourceName: "menu"))
        guard let user_id = Auth.auth().currentUser?.uid else {
            Utilities.logout()
            return
        }
        userID = user_id
        request = Drivers.child(userID).child("customerRequest")
        
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        mapView.addObserver(self, forKeyPath: "myLocation", options: .new, context: nil)
        topConstraint.constant = -180
        bottomConstraint.constant = -60
        NotificationCenter.default.addObserver(self, selector: #selector(rejectOrder(_:)), name: NSNotification.Name.init("orderCancelled"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setOnline(workingSwitch)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        mapView.removeObserver(self, forKeyPath: "myLocation")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "myLocation" {
            myLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            if workingSwitch.isOn {
                updateDriverLocation { }
            }
            if !didSetLocation {
                mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 16.0)
                didSetLocation = true
            }
        }
    }
    
    @objc func updateDriverAvailable(_ complete:@escaping () -> Void) {
        GeoFire(firebaseRef: DB.child("driversWorking")).removeKey(userID)
        isWorking = false
        updateDriverLocation {
            complete()
        }
    }
    
    @objc func updateDriverWorking(_ complete:@escaping () -> Void) {
        GeoFire(firebaseRef: DB.child("driversAvailable")).removeKey(userID)
        isWorking = true
        updateDriverLocation {
            complete()
        }
    }
    
    func updateDriverLocation(_ complete:@escaping () -> Void) {
        let geoFire = GeoFire(firebaseRef: DB.child(isWorking ? "driversWorking" : "driversAvailable"))
        geoFire.setLocation(CLLocation(latitude: myLocation.coordinate.latitude, longitude: myLocation.coordinate.longitude), forKey: userID, withCompletionBlock: { (error) in
            if error != nil {
                Utilities.alert(title: "خطأ", message: "لا يمكن تحديد موقعك")
            } else {
                complete()
            }
        })
    }
    
    @IBAction func setOnline(_ sender: UISwitch) {
        if sender.isOn {
            
            UIApplication.shared.registerForRemoteNotifications()
            updateDriverAvailable { }
            
            request.removeAllObservers()
            request.observe(.value) { (snapshot) in
                if snapshot.exists(), let value = snapshot.value as? NSDictionary, let request = Mapper<Request>().map(JSONObject: value), request.status != nil {
                    //print(request.status!)
                    switch request.status! {
                    case "Pending":
                        self.updateDriverWorking {
                            self.incomingRequest = true
                            self.getDistanceAndDuration()
                        }
                        if request.service! > 2 {
                            self.actionButton.removeTarget(self, action: #selector(self.acceptOrder(_:)), for: .touchUpInside)
                            self.actionButton.addTarget(self, action: #selector(self.acceptService(_:)), for: .touchUpInside)
                        }
                        break
                    case "accepted":
                        self.incomingRequest = true
                        self.getDistanceAndDuration()
                        if request.service! > 2 {
                            self.acceptService(Any.self)
                        } else {
                            self.acceptOrder(Any.self)
                        }
                        self.actionButton.isEnabled = true
                        break
                    case "PickUp Done":
                        self.incomingRequest = true
                        self.confirmPickup(Any.self)
                        self.actionButton.isEnabled = true
                        break
                    case "Completed":
                        self.incomingRequest = false
                        self.confirmDropoff(Any.self)
                        break
                    case "Cancelled":
                        self.incomingRequest = false
                        self.rejectOrder(Any.self)
                        break
                    default:
                        self.request.removeValue()
                        break
                    }
                } else {
                    self.updateDriverAvailable {
                        self.userImage.image = #imageLiteral(resourceName: "default")
                    }
                }
            }
        } else {
            DB.child("Tokens").child(userID).removeValue()
            request.removeAllObservers()
            GeoFire(firebaseRef: DB.child("driversAvailable")).removeKey(userID)
            GeoFire(firebaseRef: DB.child("driversWorking")).removeKey(userID)
        }
    }
    
    
    @IBAction func acceptOrder(_ sender: Any) {
        addHistoryReference()
        
        request.child("status").setValue("accepted")
        request.child("distance").setValue(distance)
        request.child("duration").setValue(duration)
        
        actionButton.setTitle("تأكيد الانطلاق", for: .normal)
        cancelButton.setTitle("الغاء الطلب", for: .normal)
        actionButton.removeTarget(self, action: #selector(acceptOrder(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(confirmPickup(_:)), for: .touchUpInside)
    }

    @IBAction func acceptService(_ sender: Any) {
        addHistoryReference()
        
        request.child("status").setValue("accepted")
        request.child("distance").setValue(distance)
        request.child("duration").setValue(duration)
        
        actionButton.setTitle("اتمام الخدمة", for: .normal)
        cancelButton.setTitle("الغاء الطلب", for: .normal)
        actionButton.removeTarget(self, action: #selector(acceptOrder(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(confirmDropoff(_:)), for: .touchUpInside)
    }

    @IBAction func rejectOrder(_ sender: Any) {
        if request != nil {
            request.child("status").setValue("rejected")
        }
        
        updateDriverAvailable { }
        
        mapView.clear()
        mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 16.0)
        
        incomingRequest = false
        actionButton.setTitle("قبول", for: .normal)
        cancelButton.setTitle("الغاء", for: .normal)
        cancelButton.isEnabled = true
        actionButton.removeTarget(self, action: #selector(confirmPickup(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(acceptOrder(_:)), for: .touchUpInside)
    }
    
    @objc func confirmPickup(_ sender: Any) {
        updateHistoryReference("PickUp Done")

        request.child("status").setValue("PickUp Done")

        self.distanceLbl.text = "مكان الوصول"
        self.durationLbl.text = "مدة الرحلة"

        actionButton.setTitle("اتمام الرحلة", for: .normal)
        cancelButton.isEnabled = false
        actionButton.removeTarget(self, action: #selector(confirmPickup(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(confirmDropoff(_:)), for: .touchUpInside)
        
        mapView.clear()
        getTripDetails()
    }
    
    @objc func confirmDropoff(_ sender: Any) {
        updateHistoryReference("Completed")

        request.child("status").setValue("Completed")
        request.child("distance").setValue(distance)
        request.child("duration").setValue(duration)

        request.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? NSDictionary, let request = Mapper<Request>().map(JSONObject: value), let customerID = request.customerRideId {
                DB.child("customerRequest").child(customerID).removeValue()
                self.request.removeValue()
            }
        }
        
        updateDriverAvailable { }
        
        mapView.clear()
        mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 16.0)
        
        incomingRequest = false
        actionButton.setTitle("قبول", for: .normal)
        cancelButton.setTitle("الغاء", for: .normal)
        cancelButton.isEnabled = true
        actionButton.removeTarget(self, action: #selector(confirmPickup(_:)), for: .touchUpInside)
        actionButton.addTarget(self, action: #selector(acceptOrder(_:)), for: .touchUpInside)
    }
    
    func addHistoryReference() {
        request.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() && !snapshot.hasChild("historyId") {
                guard let request = Mapper<Request>().map(JSONObject: snapshot.value), let customerId = request.customerRideId else { return }
                let historyRef = Drivers.child(self.userID).child("history").childByAutoId()
                self.request.child("historyId").setValue(historyRef.key)
                historyRef.setValue(true)
                Customers.child(customerId).child("history").child(historyRef.key).setValue(true)
                
                let history: [String : Any] = [
                    "customer" : customerId,
                    "destination": request.service! > 2 ? "" : request.destination ?? "",
                    "distance": self.distance,
                    "driver": self.userID,
                    "location": [
                      "from": [ "lat": request.pickupLat ?? 0.0, "lng": request.pickupLng ?? 0.0 ],
                      "to":   [ "lat": request.destinationLat ?? 0.0, "lng": request.destinationLng ?? 0.0 ]
                    ],
                    "pickup": request.pickup ?? "",
                    "rating": 0,
                    "service": "\(request.service ?? 1)",
                    "status": request.status ?? "accepted",
                    "timestamp": ceil(Date().timeIntervalSince1970)
                    ]
                DB.child("history").child(historyRef.key).setValue(history)
            }
        }, withCancel: nil)
    }
    
    func updateHistoryReference(_ status: String) {
        request.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(), let value = snapshot.value, let request = Mapper<Request>().map(JSONObject: value), let historyId = request.historyId {
                DB.child("history").child(historyId).child("status").setValue(status)
            }
        }

    }
}


extension ProviderViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        DispatchQueue.main.async {
            self.hideStatus()
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        showStatus()
    }
    
    func showStatus() {
        guard incomingRequest else { return }
        navigationController?.setNavigationBarHidden(true, animated: true)
        topConstraint.constant = 10
        bottomConstraint.constant = 20
        UIView.animate(withDuration: 0.3) {
            self.mapView.padding = UIEdgeInsets(top: 80, left: 0, bottom: 80, right: 0)
            self.view.layoutIfNeeded()
        }
    }
    
    func hideStatus(_ ended:Bool = false) {
        if ended {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        topConstraint.constant = -180
        bottomConstraint.constant = -60
        UIView.animate(withDuration: 0.3) {
            self.mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.view.layoutIfNeeded()
        }
    }
    
    func getTripDetails() {
        request.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? NSDictionary, let request = Mapper<Request>().map(JSONObject: value),
                let pickupLat = request.pickupLat, let pickupLng = request.pickupLng,
                let destinationLat = request.destinationLat, let destinationLng = request.destinationLng {
                let urlString = "\(Constants.directionsURL)\(pickupLat),\(pickupLng)&destination=\(destinationLat),\(destinationLng)&language=ar"
                let url = URL(string: urlString)
                URLSession.shared.dataTask(with: url!, completionHandler: {
                    (data, response, error) in
                    if(error == nil) {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                            let routes = json["routes"] as! NSArray
                            OperationQueue.main.addOperation({
                                for route in routes {
                                    self.drawRoute(route)
                                    
                                    let pickupMarker = GMSMarker.init(position: CLLocationCoordinate2DMake(pickupLat, pickupLng))
                                    pickupMarker.icon = GMSMarker.markerImage(with: .green)
                                    pickupMarker.map = self.mapView
                                    
                                    let dropMarker = GMSMarker.init(position: CLLocationCoordinate2DMake(destinationLat, destinationLng))
                                    dropMarker.map = self.mapView
                                    
                                    if let destination = value["destination"] as? String, let distance = ((((route as! NSDictionary).value(forKey: "legs") as! NSArray)[0] as! NSDictionary)["distance"] as! NSDictionary)["text"] as? String {
                                        self.distanceLbl.text = "مكان الوصول: \(destination) - \(distance)"
                                        self.distance = distance
                                        self.request.child("distance").setValue(distance)
                                    }
                                    if let duration = ((((route as! NSDictionary).value(forKey: "legs") as! NSArray)[0] as! NSDictionary)["duration"] as! NSDictionary)["text"] as? String {
                                        self.durationLbl.text = "زمن الرحلة: \(duration)"
                                        self.duration = duration
                                        self.request.child("duration").setValue(duration)
                                    }
                                    
                                    break
                                }
                            })
                        } catch let error as NSError{
                            print("error:\(error)")
                        }
                    }
                }).resume()
            }
        }
    }
    
    
    func getDistanceAndDuration() {
        request.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists(), let value = snapshot.value as? NSDictionary, let request = Mapper<Request>().map(JSONObject: value),
                let lat = request.pickupLat, let lng = request.pickupLng {
                let geoFire = GeoFire(firebaseRef: DB.child("driversWorking"))
                geoFire.getLocationForKey(self.userID, withCallback: { (location, error) in
                    if let location = location {

                        Customers.child(value["customerRideId"] as! String).observe(.value, with: { (snapshot) in
                            if let value = snapshot.value as? NSDictionary {
                                self.userImage.sd_setImage(with: URL.init(string: value["profileImageUrl"] as! String), placeholderImage: #imageLiteral(resourceName: "default"))
                            }
                        })

                        let urlString = "\(Constants.directionsURL)\(lat),\(lng)&destination=\(location.coordinate.latitude),\(location.coordinate.longitude)&language=ar"
                        let url = URL(string: urlString)
                        URLSession.shared.dataTask(with: url!, completionHandler: {
                            (data, response, error) in
                            if(error == nil) {
                                do {
                                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as! [String : AnyObject]
                                    let routes = json["routes"] as! NSArray
                                    OperationQueue.main.addOperation({
                                        for route in routes {
                                            self.drawRoute(route)
                                            
                                            let marker = GMSMarker.init(position: CLLocationCoordinate2DMake(lat, lng))
                                            marker.icon = #imageLiteral(resourceName: "pickup")
                                            marker.map = self.mapView
                                            if let pickup = value["pickup"] as? String, let distance = ((((route as! NSDictionary).value(forKey: "legs") as! NSArray)[0] as! NSDictionary)["distance"] as! NSDictionary)["text"] as? String {
                                                self.distanceLbl.text = "مكان الانطلاق: \(pickup) - \(distance)"
                                                self.distance = distance
                                            }
                                            if let duration = ((((route as! NSDictionary).value(forKey: "legs") as! NSArray)[0] as! NSDictionary)["duration"] as! NSDictionary)["text"] as? String {
                                                self.durationLbl.text = "زمن الرحلة: \(duration)"
                                                self.duration = duration
                                            }
                                            self.actionButton.isEnabled = true

                                            break
                                        }
                                    })
                                } catch let error as NSError{
                                    print("error:\(error)")
                                }
                            }
                        }).resume()
                    }
                })
            }
        }
    }
    
    func drawRoute(_ route: Any) {
        let routeOverviewPolyline:NSDictionary = (route as! NSDictionary).value(forKey: "overview_polyline") as! NSDictionary
        let points = routeOverviewPolyline.object(forKey: "points")
        let path = GMSPath.init(fromEncodedPath: points! as! String)
        let polyline = GMSPolyline.init(path: path)
        polyline.strokeWidth = 3
        polyline.strokeColor = UIColor.hex("013756")!
        let bounds = GMSCoordinateBounds(path: path!)
        self.mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 100.0))
        polyline.geodesic = true
        polyline.map = self.mapView
    }
}


