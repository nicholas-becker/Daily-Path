//
//  ViewController.swift
//  DailyPath
//
//  Created by Jeffrey Becker on 11/18/16.
//  Copyright © 2016 Team Tinker. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var startStopButton: UIBarButtonItem!
    var locationManager = CLLocationManager()
    var canAccessLocation = false
    var isFollowingPerson = false
    var initialLocation: CLLocation?
    var currentLocation = CLLocation()
    var currentRoute = [MKMapPoint]() {
        didSet {
            routeDisplay = MKPolyline(points: &currentRoute, count: currentRoute.count)
        }
    }
    var routeDisplay: MKPolyline? {
        willSet {
            if let path = routeDisplay {
                mapView.removeOverlay(path)
            }
        }
        didSet {
            if let path = routeDisplay where isFollowingPerson {
                    mapView.addOverlay(path)
            }
        }
    }
    //let overlayRenderer = MKOverlayRenderer()
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blueColor()
        return renderer
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.mapType = .Standard
        mapView.userTrackingMode = .Follow
        mapView.showsUserLocation = true
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = 5
        locationManager.distanceFilter = 30
        
        //var temp = MKDirectionsRequest(contentsOfURL: NSURL())
        //temp.transportType = .Walking
        
        
        // start this when the user selects option to begin new path
        //locationManager.startMonitoringSignificantLocationChanges()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            canAccessLocation = true
            locationManager.requestLocation()
        }
    }

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 1600, 1600)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last!
        if isFollowingPerson {
            currentRoute.append(MKMapPointForCoordinate(currentLocation.coordinate))
        }
        centerMapOnLocation(currentLocation)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("\(error)")
    }
    
    @IBAction func followThePerson() {
        if isFollowingPerson {
            locationManager.stopUpdatingLocation()
            isFollowingPerson = false
            startStopButton.title! = "Start Running"
            
            // complete route
        } else {
            if canAccessLocation {
                locationManager.startUpdatingLocation()
                isFollowingPerson = true
                startStopButton.title! = "Stop Running"
                
                // start route
                currentLocation = mapView.userLocation.location!
                initialLocation = currentLocation
                currentRoute.removeAll()
                currentRoute.append(MKMapPointForCoordinate(currentLocation.coordinate))
            } else {
                let alert = UIAlertController(title: "Access Error", message: "Location information is unavailable. Please update your privacy settings to allow this app to access your location.", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(defaultAction)
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }

}
