//
//  ViewController.swift
//  Redcupa_ios
//
//  Created by Alonso Martinez  on 5/24/17.
//  Copyright © 2017 Redcupa. All rights reserved.
//

import UIKit

import Firebase
import FirebaseAuthUI
import FirebaseDatabase
import FirebaseFacebookAuthUI
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleMaps
import MaterialComponents
import GooglePlaces
import GooglePlacePicker

class MyMapView: UIViewController, FUIAuthDelegate {
    
    var pickedCoordinates: CLLocationCoordinate2D?
    
    var ref_events : DatabaseReference!
    var events = [Event]()
    var googleMapView: GMSMapView?
    let customBlue = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1)
    
    override func loadView() {
        
        self.ref_events = Database.database().reference().child("Events_parent")

        
        //TODO: Center map on current location, not hardcoded LatLng
        let camera = GMSCameraPosition.camera(withLatitude: 19.0412967, longitude: -98.20619959999999, zoom: 11)
        let googleMapView = GMSMapView.map(withFrame: .zero, camera: camera)
        
        //googleMapView.isMyLocationEnabled = true
        
 
        //Firebase querying for event data. Cannot be done on outside function as marker drawing is 
        // only supported from within loadView()
        ref_events.observe(.childAdded, with: { (snapshot) in
            
            
            let event = snapshot.value as! [String:AnyObject]
            let eventLat = event["eventLatitude"] as! Double
            let eventLng = event["eventLongitude"] as! Double
            let eventName = event["eventName"] as! String
            
            let position = CLLocationCoordinate2D(latitude: eventLat, longitude: eventLng)
            let marker = GMSMarker(position: position)
            marker.title = eventName
            
            marker.map = googleMapView
            
        }, withCancel: nil)
        //End Firebase querying. 
        //Note: .observe() functions are called asynchronous, so called last.
        
        
        
        self.view = googleMapView
    }
 

    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        checkLoggedIn()
        
        //Drawing FAB
        let floatingButton = MDCFloatingButton()
        floatingButton.backgroundColor = customBlue
        floatingButton.setTitle("+", for: .normal)
        floatingButton.setTitleColor( UIColor.white, for: .normal)
        floatingButton.sizeToFit()
        floatingButton.addTarget(self, action: #selector(fabClicked), for: .touchUpInside)
        self.view.addSubview(floatingButton)
        
    }
    
    func fabClicked(){
        let config = GMSPlacePickerConfig(viewport: nil)
        let placePicker = GMSPlacePicker(config: config)
        
        placePicker.pickPlace(callback: { (place, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            guard let place = place else {
                print("No place selected")
                return
            }
            //Called when place selected correctly
            print("Place name \(place.name)")
            print(place.coordinate)
            print("Place address \(String(describing: place.formattedAddress))")
            print("Place attributions \(String(describing: place.attributions))")
            
            self.pickedCoordinates = place.coordinate
        
            //Redirects to newPost screen and passes the coordinates selected
            self.performSegue(withIdentifier: "NewPostSegue", sender: self)
            
        })
    }
    
    //Passes the coordinates picked by place picker through segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewPostSegue" && self.pickedCoordinates != nil {
            
            let dvc = segue.destination as! NewPostController
            dvc.passedCoordinates = self.pickedCoordinates
        }
    }
    
    func checkLoggedIn() {
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                
            } else {
                // No user is signed in.
                self.login()
            }
        }
    }
    
    func login() {
        //TODO: Add users to database under Users_parent
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self
        
    
        let options = FirebaseApp.app()?.options
        let clientId = options?.clientID
        
        let facebookProvider = FUIFacebookAuth()
        
        authUI?.providers = [facebookProvider]
        
        let authViewController = authUI?.authViewController()
        self.present(authViewController!, animated: true, completion: nil)
    }
    

    @IBAction func logOut(_ sender: UIButton) {
        try! Auth.auth().signOut()
    }
 
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if error != nil {
            //Problem signing in
            login()
        }else {
            //User is in! Here is where we code after signing in
            
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }

}
