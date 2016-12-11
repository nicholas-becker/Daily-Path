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
                path.title = "Running Path"
                mapView.addOverlay(path)
            }
        }
    }
    var searchQuadrant = 3
    var bestPosMatch = Double.infinity
    var bestNegMatch = -Double.infinity
    var startRoute = MKRoute()
    var bestRoute = MKRoute()
    var loadingPath = false
    var loadedPath = Path() {
        didSet {
            loadedDisplay = MKPolyline(points: &loadedPath.points, count: loadedPath.points.count)
        }
    }
    var loadedDisplay: MKPolyline? {
        willSet {
            if let path = loadedDisplay {
                mapView.removeOverlay(path)
            }
        }
        didSet {
            if let path = loadedDisplay where loadedDisplay?.pointCount > 0{
                path.title = "Loaded Path"
                mapView.userTrackingMode = .None
                mapView.centerCoordinate = MKCoordinateForMapPoint(path.points().memory)
                mapView.addOverlay(path)
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        print((overlay as! MKPolyline).pointCount)
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blueColor()
        renderer.alpha = 0.5
        if overlay.title! == "Loaded Path" {
            renderer.strokeColor = UIColor.redColor()
        }
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
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            canAccessLocation = true
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
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
            mapView.userTrackingMode = .Follow
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("\(error)")
    }
    
    @IBAction func followThePerson() {
        if isFollowingPerson {
            startStopButton.title! = "Start Running"
            
            // complete route
            savePath(currentRoute)
            isFollowingPerson = false
        } else {
            if canAccessLocation {
                isFollowingPerson = true
                startStopButton.title! = "Stop Running"
                
                // start route
                currentLocation = mapView.userLocation.location!
                previousLocation = currentLocation
                currentRoute.points.removeAll()
                currentRoute.pathLength = 0
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
    
    func findPath(length: Double, start: CLLocationCoordinate2D,  middle: CLLocationCoordinate2D) {
        loadedPath = Path()
        
        let directionsRequest = MKDirectionsRequest()
        var directions = MKDirections(request: directionsRequest)
        directionsRequest.transportType = .Walking
        directionsRequest.requestsAlternateRoutes = true
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate, addressDictionary: nil))
        
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: middle, addressDictionary: nil))
        directions = MKDirections(request: directionsRequest)
        directions.calculateDirectionsWithCompletionHandler() { serverResponse, error in
            if let badStuff = error {
                print(badStuff)
                if (self.loadingPath) {
                    let notice = UIAlertController(title: "Inaccurate Path", message: "A path of the desired distance could not be found. The closest path found is displayed. You may need to restart the app to use the 'Find Path' option again.", preferredStyle: .Alert)
                    notice.addAction(UIAlertAction(title: "OK", style: .Default) { _ in
                        self.loadPath(self.startRoute, returnRoute: self.bestRoute)
                        })
                    self.presentViewController(notice, animated: true, completion: nil)
                }
            } else if let response = serverResponse {
                for route in response.routes {
                        self.completePath(route, desiredLength: length, middle: directionsRequest.destination!, end: directionsRequest.source!)
                }
            }
        }
    }
    
    func completePath(firstHalf: MKRoute, desiredLength: Double, middle: MKMapItem, end: MKMapItem){
        let directionsRequest = MKDirectionsRequest()
        directionsRequest.source = middle
        directionsRequest.destination = end
        directionsRequest.requestsAlternateRoutes = true
        directionsRequest.transportType = .Walking
        let directions = MKDirections(request: directionsRequest)
        if !self.loadingPath { return }
        directions.calculateDirectionsWithCompletionHandler() { serverResponse, error in
            if let badStuff = error {
                print(badStuff)
                if (self.loadingPath) {
                    let notice = UIAlertController(title: "Inaccurate Path", message: "A path of the desired distance could not be found. The closest path found is displayed. You may need to restart the app to use the 'Find Path' option again.", preferredStyle: .Alert)
                    notice.addAction(UIAlertAction(title: "OK", style: .Default) { _ in
                        self.loadPath(firstHalf, returnRoute: self.bestRoute)
                        })
                    self.presentViewController(notice, animated: true, completion: nil)
                }
            } else if let response = serverResponse {
                let currentLength = self.convertMetersToMiles(firstHalf.distance)
                print("first half: \(currentLength)")
                for route in response.routes {
                    let pathDistance = self.convertMetersToMiles(route.distance)
                    print("total: \(pathDistance + currentLength)")
                    let diff = desiredLength - (currentLength + pathDistance)
                    if diff > 0 && diff < self.bestPosMatch {
                        self.bestPosMatch = diff
                        if (self.bestPosMatch < abs(self.bestNegMatch)) {
                            self.bestRoute = route
                            self.startRoute = firstHalf
                        }
                    } else if diff < 0 && diff > self.bestNegMatch {
                        self.bestNegMatch = diff
                        if (abs(self.bestNegMatch) < self.bestPosMatch) {
                            self.bestRoute = route
                            self.startRoute = firstHalf
                        }
                    }
                    
                    if abs(diff) < desiredLength * 0.005 && self.loadingPath {
                        self.loadPath(firstHalf, returnRoute: route)
                        return
                    }
                }
                
                print("closest pos diff: \(self.bestPosMatch)")
                print("closes neg diff: \(self.bestNegMatch)")
                // try again with a better guess
                var moveDistance = (self.bestPosMatch + self.bestNegMatch) / 2
                if self.bestPosMatch == Double.infinity {
                    moveDistance = self.bestNegMatch / 4
                } else if self.bestNegMatch == -Double.infinity {
                    moveDistance = self.bestPosMatch / 4
                }
                
                let newGuess = self.getPossibleDestination(middle.placemark.coordinate, distance: moveDistance)
                self.findPath(desiredLength, start: end.placemark.coordinate, middle: newGuess)
            }
        }
    }
    
    func loadPath(outRoute: MKRoute, returnRoute: MKRoute) {
        if(!self.loadingPath || outRoute.polyline.pointCount == 0 || returnRoute.polyline.pointCount == 0) { return }
        self.loadingPath = false
        self.loadedPath.pathLength = convertMetersToMiles(outRoute.distance + returnRoute.distance)
        let outPoints = outRoute.polyline.points()
        for point in outPoints.stride(through: outPoints.advancedBy(outRoute.polyline.pointCount - 1), by: 1) {
            self.loadedPath.points.append(point.memory)
        }
        let returnPoints = returnRoute.polyline.points()
        for point in returnPoints.stride(through: returnPoints.advancedBy(returnRoute.polyline.pointCount - 1), by: 1) {
            self.loadedPath.points.append(point.memory)
        }
        
        self.loadedDisplay = MKPolyline(points: &self.loadedPath.points, count: self.loadedPath.points.count)
        self.savePath(self.loadedPath)
    }
    
    func getPossibleDestination(start: CLLocationCoordinate2D, distance: Double) -> CLLocationCoordinate2D {
        var destinationLat = 0.0
        var destinationLon = 0.0
        var centerLat = 0.0
        switch (searchQuadrant % 4) {
        case 0:
            destinationLat = start.latitude + distance / 69.172 / 2
            centerLat = (start.latitude + destinationLat) / 2
            destinationLon = start.longitude - distance / (cos(centerLat) * 69.172) / 2
        case 1:
            destinationLat = start.latitude - distance / 69.172 / 2
            centerLat = (start.latitude + destinationLat) / 2
            destinationLon = start.longitude - distance / (cos(centerLat) * 69.172) / 2
        case 2:
            destinationLat = start.latitude - distance / 69.172 / 2
            centerLat = (start.latitude + destinationLat) / 2
            destinationLon = start.longitude + distance / (cos(centerLat) * 69.172) / 2
        case 3:
            destinationLat = start.latitude + distance / 69.172 / 2
            centerLat = (start.latitude + destinationLat) / 2
            destinationLon = start.longitude + distance / (cos(centerLat) * 69.172) / 2
        default:
            print("switch is exhausted")
        }
        return CLLocationCoordinate2D(latitude: destinationLat, longitude: destinationLon)
    }
    
    @IBAction func findPath() {
        let findPathPrompt = UIAlertController(title: "Find Path", message: "Enter the desired path distance in miles", preferredStyle: .Alert)
        findPathPrompt.addTextFieldWithConfigurationHandler({
            (textField) -> Void in
            textField.placeholder = "TotalDistance"
            textField.keyboardType = .DecimalPad
        })
        let calculateAction = UIAlertAction(title: "Calculate", style: .Default) {
            [weak findPathPrompt] (action) -> Void in
            let distance = Double(findPathPrompt!.textFields![0].text!)!
            self.loadingPath = true
            self.bestNegMatch = -Double.infinity
            self.bestPosMatch = Double.infinity
            self.startRoute = MKRoute()
            self.bestRoute = MKRoute()
            self.findPath(distance, start: self.currentLocation.coordinate, middle: self.getPossibleDestination(self.currentLocation.coordinate, distance: distance / 2))
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        findPathPrompt.addAction(cancelAction)
        findPathPrompt.addAction(calculateAction)
        
        presentViewController(findPathPrompt, animated: true, completion: nil)
    }
    
    func savePath(path: Path) {
        let savePrompt = UIAlertController(title: "Save Path?", message: "If you would like to save the completed path, please enter a name and press Save.", preferredStyle: .Alert)
        savePrompt.addTextFieldWithConfigurationHandler({
            (textField) -> Void in
            textField.placeholder = "\(round(path.pathLength * 100) / 100) mile run"
        })
        let saveAction = UIAlertAction(title: "Save", style: .Default) {
            [weak savePrompt] (action) -> Void in
            path.pathName = savePrompt!.textFields![0].text!
            self.store.createPath(path, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        savePrompt.addAction(cancelAction)
        savePrompt.addAction(saveAction)
        
        presentViewController(savePrompt, animated: true, completion: nil)
    }
    
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {
        let temp = routeDisplay
        routeDisplay = temp
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
}

