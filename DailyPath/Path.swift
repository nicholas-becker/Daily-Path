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
    var pathName: String = ""
    var pathLength: Double = 0
    var points: [MKMapPoint] = [MKMapPoint]()
    var jsonDictionary: NSDictionary {
        var pointDictionary = Dictionary<String, Dictionary<String, Double>>()
        for (index, point) in points.enumerate() {
            pointDictionary["\(index)"] = ["x" : point.x, "y" : point.y]
        }
        
        return [
            "pathName" : self.pathName,
            "pathLength" : self.pathLength,
            "points" : pointDictionary
        ]
    }
    
    convenience init(pathName: String, pathLength: Double, points: [MKMapPoint]) {
        self.init()
        
        self.pathName = pathName
        self.pathLength = pathLength
        self.points = points
    }
    
    static func deserialize(data: NSData) -> Path {
        let decodedJson = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as! Dictionary<String, AnyObject>
        let pathName = decodedJson?["pathName"] as! String
        let pathLength = decodedJson?["pathLength"] as! Double
        let pointsDictionary = decodedJson?["points"] as! Dictionary<String, Dictionary<String, Double>>
        var points = [MKMapPoint]()
        
        for pointNum in 0..<pointsDictionary.count {
            points.append(MKMapPoint(x: pointsDictionary["\(pointNum)"]!["x"]!, y: pointsDictionary["\(pointNum)"]!["y"]!))
        }
        
        return Path(pathName: pathName, pathLength: pathLength, points: points)
    }
    
    func save() {
        let json = try! NSJSONSerialization.dataWithJSONObject(jsonDictionary, options: [])
        print(json)
    }
}