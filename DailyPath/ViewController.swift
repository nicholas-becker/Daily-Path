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
    var loadedPath = Path()
    var loadedDisplay: MKPolyline? {
        willSet {
            if let path = loadedDisplay {
                mapView.removeOverlay(path)
            }
        }
        didSet {
            if let path = loadedDisplay {
                path.title = "Loaded Path"
                mapView.addOverlay(path)
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
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
    
    func findPath(length: Double, possibleEnd: CLLocationCoordinate2D) {
        loadedPath = Path()
        
        let directionsRequest = MKDirectionsRequest()
        var directions = MKDirections(request: directionsRequest)
        directionsRequest.transportType = .Walking
        directionsRequest.requestsAlternateRoutes = true
        directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate, addressDictionary: nil))
        
        directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: possibleEnd, addressDictionary: nil))
        directions = MKDirections(request: directionsRequest)
        directions.calculateDirectionsWithCompletionHandler() { serverResponse, error in
            if let response = serverResponse {
                var bestMatch = Double.infinity
                for route in response.routes {
                    let pathDistance = self.convertMetersToMiles(route.distance)
                    print("path distance is: \(pathDistance)")
                    let diff = length / 2 - pathDistance
                    if (abs(diff) < abs(bestMatch)) {
                        bestMatch = diff
                    }
                    
                    if abs(diff) < 0.01 {
                        self.loadedPath.pathLength = pathDistance
                        let points = route.polyline.points()
                        for point in points.stride(through: points.advancedBy(route.polyline.pointCount - 1), by: 1) {
                            self.loadedPath.points.append(point.memory)
                        }
                        
                        self.completePath(directionsRequest.destination!, home: directionsRequest.source!)
                        return
                    }
                }
                // try again with a better guess
                self.findPath(length, possibleEnd: self.getPossibleDestination(possibleEnd, distance: bestMatch))
            }
        }
    }
    
    func completePath(halfway: MKMapItem, home: MKMapItem){
        let directionsRequest = MKDirectionsRequest()
        directionsRequest.source = halfway
        directionsRequest.destination = home
        let directions = MKDirections(request: directionsRequest)
        directions.calculateDirectionsWithCompletionHandler() { serverResponse, error in
            let route = serverResponse!.routes.first!
            let pathDistance = self.convertMetersToMiles(route.distance)
            self.loadedPath.pathLength += pathDistance
            
            let polyline = route.polyline
            let points = polyline.points()
            for point in points.stride(through: points.advancedBy(polyline.pointCount - 1), by: 1) {
                self.loadedPath.points.append(point.memory)
            }
            print("total distance: \(self.loadedPath.pathLength)")
            self.loadedDisplay = MKPolyline(points: &self.loadedPath.points, count: self.loadedPath.points.count)
            self.savePath(self.loadedPath)
        }
    }
    
    func getPossibleDestination(start: CLLocationCoordinate2D, distance: Double) -> CLLocationCoordinate2D {
        let destinationLat = start.latitude + distance / 69.172 / 2
        let centerLat = (start.latitude + destinationLat) / 2
        let destinationLon = start.longitude + distance / (cos(centerLat) * 69.172) / 2
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
            self.findPath(distance, possibleEnd: self.getPossibleDestination(self.currentLocation.coordinate, distance: distance))
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
}

