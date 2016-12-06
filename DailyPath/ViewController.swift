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
    var store: PathStore!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var startStopButton: UIBarButtonItem!
    @IBOutlet var currentDistance: UILabel!
    var locationManager = CLLocationManager()
    var canAccessLocation = false
    var isFollowingPerson = false
    var previousLocation: CLLocation?
    var currentLocation = CLLocation()
    var currentRoute = Path()
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
        locationManager.desiredAccuracy = 1
        locationManager.distanceFilter = 10
        currentDistance.text = nil
        
        //var temp = MKDirectionsRequest(contentsOfURL: NSURL())
        //temp.transportType = .Walking
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            canAccessLocation = true
            locationManager.startUpdatingLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        previousLocation = currentLocation
        currentLocation = locations.last!
        
        if isFollowingPerson {
            currentRoute.points.append(MKMapPointForCoordinate(currentLocation.coordinate))
            currentRoute.pathLength += getDistanceInMiles(previousLocation!, end: currentLocation)
            currentDistance.text = "Dist: \(round(currentRoute.pathLength * 100) / 100) mi"
            routeDisplay = MKPolyline(points: &currentRoute.points, count: currentRoute.points.count)
        }
        mapView.userTrackingMode = .Follow
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("\(error)")
    }
    
    @IBAction func followThePerson() {
        if isFollowingPerson {
            startStopButton.title! = "Start Running"
            
            // complete route
            let savePrompt = UIAlertController(title: "Save Path?", message: "If you would like to save the completed path, please enter a name and press Save.", preferredStyle: .Alert)
            savePrompt.addTextFieldWithConfigurationHandler({
                (textField) -> Void in
                textField.text = "EnterName"
            })
            let saveAction = UIAlertAction(title: "Save", style: .Default) {
                [weak savePrompt] (action) -> Void in
                self.currentRoute.pathName = savePrompt!.textFields![0].text!
                self.currentRoute.save()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            
            savePrompt.addAction(cancelAction)
            savePrompt.addAction(saveAction)
            
            presentViewController(savePrompt, animated: true, completion: nil)
            isFollowingPerson = false
        } else {
            if canAccessLocation {
                isFollowingPerson = true
                startStopButton.title! = "Stop Running"
                
                // start route
                currentLocation = mapView.userLocation.location!
                previousLocation = currentLocation
                currentRoute.points.removeAll()
                currentRoute.points.append(MKMapPointForCoordinate(currentLocation.coordinate))
                routeDisplay = MKPolyline(points: &currentRoute.points, count: currentRoute.points.count)
            } else {
                let alert = UIAlertController(title: "Access Error", message: "Location information is unavailable. Please update your privacy settings to allow this app to access your location.", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(defaultAction)
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func getDistanceInMiles(start: CLLocation, end: CLLocation) -> Double {
        return convertMetersToMiles(abs(start.distanceFromLocation(end)))
    }
    
    func convertMetersToMiles(meters: Double) -> Double {
        return meters * 100 / 2.54 / 12 / 5280
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //print("going from path to path")
        // if the triggered segue is the "ShowPaths" segue
        if segue.identifier == "ShowPaths" {
                let pathViewController = segue.destinationViewController as! PathListTableViewController
                pathViewController.store = PathStore()
                pathViewController.pathStore = [Path]()
        }
    }
    
    func createPath(length: Double) -> Path {
        let newPath = Path(pathName: "", pathLength: 0, points: [MKMapPoint]())
        var getBetterDirections = true
        let directions = MKDirections()
        let returnDirections = MKDirections()
        
        let directionsRequest = MKDirectionsRequest()
        directionsRequest.transportType = .Walking
        directionsRequest.requestsAlternateRoutes = true
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate, addressDictionary: nil))
        var destination = getPossibleDestination(currentLocation.coordinate, distance: length)
        
        while(getBetterDirections) {
            if(!directions.calculating && !returnDirections.calculating) {
                directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination, addressDictionary: nil))
                directions.calculateDirectionsWithCompletionHandler() {serverResponse,error in
                    if let response = serverResponse {
                        var bestMatch = Double.infinity
                        for route in response.routes {
                            let pathDistance = self.convertMetersToMiles(route.distance)
                            let diff = pathDistance - length / 2
                            if (abs(diff) < abs(bestMatch)) {
                                bestMatch = diff
                            }
                            
                            if abs(diff) < 0.01 {
                                newPath.pathLength = pathDistance
                                let points = route.polyline.points()
                                for point in points.stride(through: points, by: 1) {
                                    newPath.points.append(point.memory)
                                }
                                
                                //TODO
                                // get return directions
                                getBetterDirections = false
                                return
                            }
                        }
                        
                        // get different destination
                        destination = self.getPossibleDestination(destination, distance: bestMatch)
                    }
                }
            }
        }
        
        
        return newPath
    }
    
    func getPossibleDestination(start: CLLocationCoordinate2D, distance: Double) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D()
    }
}

