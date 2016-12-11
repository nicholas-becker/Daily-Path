//
//  Path.swift
//  DailyPath
//
//  Created by Nicholas Becker on 11/28/16.
//  Copyright © 2016 Team Tinker. All rights reserved.
//

import Foundation
import MapKit

class Path: NSObject {
    var id: Int = 0
    var pathName: String = ""
    var pathLength: Double = 0
    var points: [MKMapPoint] = [MKMapPoint]()
    
    convenience init(pathName: String, pathLength: Double, points: [MKMapPoint],id: Int = 0) {
        self.init()
        
        self.id = id
        self.pathName = pathName
        self.pathLength = pathLength
        self.points = points
    }
}