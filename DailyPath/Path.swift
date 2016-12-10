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
    var jsonDictionary: NSDictionary {
        var pointDictionary = Dictionary<String, Dictionary<String, Double>>()
        for (index, point) in points.enumerate() {
            pointDictionary["\(index)"] = ["x" : point.x, "y" : point.y]
        }
        
        return [
            "id": self.id,
            "path_name" : self.pathName,
            "path_dist" : self.pathLength,
            "points" : pointDictionary
        ]
    }
    
    convenience init(pathName: String, pathLength: Double, points: [MKMapPoint],id: Int = 0) {
        self.init()
        
        self.id = id
        self.pathName = pathName
        self.pathLength = pathLength
        self.points = points
    }
    
    static func deserialize(data: NSData) -> Path {
        let decodedJson = try? NSJSONSerialization.JSONObjectWithData(data, options: []) as! Dictionary<String, AnyObject>
        let id = decodedJson?["id"] as! Int
        let pathName = decodedJson?["path_name"] as! String
        let pathLength = decodedJson?["path_dist"] as! Double
        let pointsDictionary = decodedJson?["points"] as! Dictionary<String, Dictionary<String, Double>>
        var points = [MKMapPoint]()
        
        for pointNum in 0..<pointsDictionary.count {
            points.append(MKMapPoint(x: pointsDictionary["\(pointNum)"]!["x"]!, y: pointsDictionary["\(pointNum)"]!["y"]!))
        }
        
        return Path(pathName: pathName, pathLength: pathLength, points: points,id: id)
    }
    
    func save() {
        let json = try! NSJSONSerialization.dataWithJSONObject(jsonDictionary, options: [])
        
    }
}