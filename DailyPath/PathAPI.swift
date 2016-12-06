//
//  PathAPI.swift
//  DailyPath
//
//  Created by Nicholas Becker on 12/3/16.
//  Copyright © 2016 Team Tinker. All rights reserved.
//

import Foundation
import MapKit

let myToken = "database token"
let mySecret = "database secret"

// TO DO
enum Method: String {
    // these are still from Trello and need to be changed
    case GET = "1/"
    case POST = "1/paths?"
    case PUT = "1/paths/"
    case DELETE = "1/paths"
}

enum PathsResult {
    case Success([Path])
    case Failure(ErrorType)
}
enum PathResult {
    case Success(Path)
    case Failure(ErrorType)
}

enum PathError: ErrorType {
    case InvalidJSONData
}

struct PathAPI {
    private static let baseURLString = "https://blooming-everglades-93070.herokuapp.com/"
    private static let APIKey = "database key"
    
    static func pathsFromJSONData(data: NSData) -> PathsResult {
        do {
            let jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            
            guard let paths = jsonObject as? [NSDictionary] else {
                // The JSON structure doesn't match our expectations
                return .Failure(PathError.InvalidJSONData)
            }
            var names = [String]()
            var lengths = [Double]()
            var points = [[MKMapPoint]]()
            for each in paths {
                guard let theName = each["path_name"] as? String, theLength = each["path_dist"] as? Double, thePoints = each["points"] as? [NSDictionary] else {
                    return .Failure(PathError.InvalidJSONData)
                }
                names.append(theName)
                lengths.append(theLength)
                var pointArray = [MKMapPoint]()
                for stuff in thePoints {
                    guard let x = stuff["x"] as? Double, y = stuff["y"] as? Double else {
                        return .Failure(PathError.InvalidJSONData)
                    }
                    pointArray.append(MKMapPoint(x: x, y: y))
                }
                points.append(pointArray)
            }
            
            var finalPaths = [Path]()
            for each in names {
                finalPaths.append( Path(pathName: each, pathLength: lengths[names.indexOf(each)!], points: points[names.indexOf(each)!]) )
            }
            
            if finalPaths.count == 0 && paths.count > 0 {
                // we couldn't parse the paths and one existed
                return .Failure(PathError.InvalidJSONData)
            }
            return .Success(finalPaths)
        }
        catch let error {
            return .Failure(error)
        }
    }
    
    static func pathFromJSONData(data: NSData) -> PathResult {
        do {
            let jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            print(jsonObject)
            guard let path = jsonObject as? [NSObject:AnyObject], name = path["path_name"] as? String, length = path["path_dist"] as? Double, points = path["points"] as? [NSDictionary] else {
                // The JSON structure doesn't match our expectations
                return .Failure(PathError.InvalidJSONData)
            }
            
            var pointArray = [MKMapPoint]()
            for stuff in points {
                guard let x = stuff["x"] as? Double, y = stuff["y"] as? Double else {
                    return .Failure(PathError.InvalidJSONData)
                }
                pointArray.append(MKMapPoint(x: x, y: y))
            }
            
            let finalPath = Path(pathName: name, pathLength: length, points: pointArray)
            
            return .Success(finalPath)
        }
        catch let error {
            return .Failure(error)
        }
    }
    
    // Everything below needs to be updated once we know how to add stuff to Johns database
    // TO DO
    private static func pathURL(method method: Method, urlString: String, parameters: [String:String]?) -> NSURL {
        let startString = baseURLString + method.rawValue + urlString
        let components = NSURLComponents(string: startString)!
        var queryItems = [NSURLQueryItem]()
        let baseParams = ["key": APIKey, "token": myToken]
        
        for (key, value) in baseParams {
            let item = NSURLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = NSURLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        
        return components.URL!
    }
    // TO DO
    static func GetPathsURL() -> NSURL {
        return pathURL(method: .GET, urlString: "members/me/paths?", parameters: [:])
    }
    // TO DO
    static func GetPathURL(path: Path) -> NSURL {
        return pathURL(method: .GET, urlString: "paths/\(path)/paths?", parameters: [:])
    }
    // TO DO
    static func CreatePathURL(thePath: Path) -> NSURL {
        var pathPoints: String = ""
        for each in thePath.points {
            pathPoints += ",x:\(each.x),y:\(each.y)"
        }
        return pathURL(method: .POST, urlString: "", parameters: ["path_name": thePath.pathName, "path_dist": thePath.pathLength.description, "points": pathPoints])
    }
    // TO DO
    static func DeletePathURL(path: Path) -> NSURL {
        return pathURL(method: .DELETE, urlString: "/\(path)?", parameters: [:])
    }
    
    // TO DO
    static func EditPathURL(name: String, desc: String, pathId: String) -> NSURL {
        return pathURL(method: .PUT, urlString: "\(pathId)?", parameters: ["name": name, "desc": desc, "due": "null"])
    }
    // TO DO
    static func MovePathURL(pathId: String, pos: String) -> NSURL {
        return pathURL(method: .PUT, urlString: "\(pathId)/pos?", parameters: ["pos": pos])
    }
}