//
//  ViewController.swift
//  DailyPath
//
//  Created by Jeffrey Becker on 11/18/16.
//  Copyright © 2016 Team Tinker. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    var locationManager: CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.mapType = .Hybrid
        print(mapView.userLocation)
        mapView.userTrackingMode = .Follow
        //var temp = MKDirectionsRequest(contentsOfURL: NSURL())
        //temp.transportType = .Walking
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

