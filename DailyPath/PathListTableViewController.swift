//
//  PathListTableViewController.swift
//  DailyPath
//
//  Created by Nicholas Becker on 12/3/16.
//  Copyright © 2016 Team Tinker. All rights reserved.
//

import UIKit
import MapKit

class PathStore {
    let session: NSURLSession = {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        return NSURLSession(configuration: config)
    }()
    
    func getAllPaths(completion completion: (PathsResult) -> Void) {
        let url = PathAPI.GetPathsURL()
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let result = self.processGetAllPathsRequest(data: data, error: error)
            completion(result)
        }
        task.resume()
    }
    func processGetAllPathsRequest(data data: NSData?, error: NSError?) ->  PathsResult{
        guard let jsonData = data else {
            return .Failure(error!)
        }
        return PathAPI.pathsFromJSONData(jsonData)
    }
    
    func createPath(thePath: Path, completion: ((PathResult) -> Void)?) {
        let url = PathAPI.CreatePathURL(thePath)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let result = self.processCreatePathRequest(data: data, error: error)
            completion?(result)
        }
        task.resume()
    }
    func processCreatePathRequest(data data: NSData?, error: NSError?) ->  PathResult{
        guard let jsonData = data else {
            print(data)
            return .Failure(error!)
        }
        return PathAPI.pathFromJSONData(jsonData)
    }
    /*
    func editPath(completion: (PathResult) -> Void) {
        let url = PathAPI.EditPathURL(parentPath.name, desc: parentPath.desc, pathId: parentPath.id)
        //print(url)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        //print(request)
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let result = self.processEditPathRequest(data: data, error: error)
            completion(result)
        }
        task.resume()
    }
    func processEditPathRequest(data data: NSData?, error: NSError?) ->  PathResult{
        guard let jsonData = data else {
            //print(data)
            return .Failure(error!)
        }
        return PathAPI.pathFromJSONData(jsonData)
    }*/
    
    func deletePath(path: Path, completion: (PathResult) -> Void) {
        let url = PathAPI.DeletePathURL(path)
        //print(url)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "DELETE"
        //print(request)
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let result = self.processDeletePathRequest(data: data, error: error)
            completion(result)
        }
        task.resume()
    }
    func processDeletePathRequest(data data: NSData?, error: NSError?) ->  PathResult{
        guard let jsonData = data else {
            //print(data)
            return .Failure(error!)
        }
        return PathAPI.pathFromJSONData(jsonData)
    }
    func movePath(pathId: String, pos: String, completion: (PathResult) -> Void) {
        let url = PathAPI.MovePathURL(pathId, pos: pos)
        //print(url)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "PUT"
        //print(request)
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) -> Void in
            
            let result = self.processMovePathRequest(data: data, error: error)
            completion(result)
        }
        task.resume()
    }
    func processMovePathRequest(data data: NSData?, error: NSError?) ->  PathResult{
        guard let jsonData = data else {
            //print(data)
            return .Failure(error!)
        }
        return PathAPI.pathFromJSONData(jsonData)
    }
}

class PathListTableViewController: UITableViewController {
    var store: PathStore!
    var pathStore: [Path]!
    
    func removePath(path: Path) {
        if let index = pathStore.indexOf(path) {
            pathStore.removeAtIndex(index)
        }
    }
    
    func movePathAtIndex(fromIndex: Int, toIndex: Int) {
        if fromIndex == toIndex {
            return
        }
        
        // get reference to path being moved so you can reinsert it
        let movedPath = pathStore[fromIndex]
        // remove path from array
        pathStore.removeAtIndex(fromIndex)
        // insert path in array at new location
        pathStore.insert(movedPath, atIndex: toIndex)
    }
    
    @IBAction func addBlankPath(sender: AnyObject) {
        addNewPath(self, givenPath: Path(pathName: "New Path", pathLength: 0, points: [MKMapPoint]()))
    }
    @IBAction func addNewPath(sender: AnyObject, givenPath: Path?) {
        // create a new path and add it to the store
        if givenPath == nil {
            let newPath = Path(pathName: "new_Path", pathLength: 0, points: [MKMapPoint]())
            pathStore.append(newPath)
        } else {
            pathStore.append(givenPath!)
        }
        
        // the new path was appended, so it is at the end of the array, but find it cuz the book did so
        if let index = pathStore.indexOf(givenPath!) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            // Insert this new row into the table
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    @IBAction func toggleEditingMode(sender: AnyObject) {
        // If you are currently in editing mode...
        if editing {
            // change text of button to inform user of state
            sender.setTitle("Edit", forState: .Normal)
            
            // turn off editing mode
            setEditing(false, animated: true)
        }
        else {
            // change text of button to inform user of state
            sender.setTitle("Done", forState: .Normal)
            
            // Enter editing mode
            setEditing(true, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        // update the model
        movePathAtIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("displaying \(pathStore.count) cells")
        return pathStore.count
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // if the table view is asking to commit a delete command...
        if editingStyle == .Delete {
            let path = pathStore[indexPath.row]
            
            let title = "Delete \(path.pathName)?"
            let message = "Are you sure you want to delete this path?"
            
            let ac = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            ac.addAction(cancelAction)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { (action) -> Void in
                // remove the path from the store
                self.removePath(path)
                
                // also remove that row from the table view with an animation
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            })
            ac.addAction(deleteAction)
            
            // present the alert controller
            presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //get a new or recycled cell
        let cell = tableView.dequeueReusableCellWithIdentifier("UITableViewCellPath", forIndexPath: indexPath)
        
        // Set the text on the cell with the name of the path
        // that is at the nth index of paths, where n = row this cell
        // will appear in on the tableview
        let path = pathStore[indexPath.row]
        
        cell.textLabel?.text = path.pathName
        cell.detailTextLabel?.text = "\(path.pathLength) mi"
        cell.tag = indexPath.row
        
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the height of the status bar
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let insets = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        store.getAllPaths() {
            (PathResult) -> Void in switch PathResult {
            case let .Success(paths):
                for each in paths {
                    self.addNewPath(self, givenPath: each)
                }
                //print("successfully found \(paths.count) paths")
                for each in self.pathStore{
                    //print(each.pathName)
                    //print(each.pathLength)
                }
            case let .Failure(error):
                print("Error fetching paths: \(error)")
            }
            
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                self.tableView.reloadData()
            }
            
            
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let parent = self.parentViewController as! UINavigationController
        (parent.viewControllers[parent.viewControllers.count-2] as! ViewController).loadedPath = pathStore[indexPath.row]
        self.performSegueWithIdentifier("unwindToViewController", sender: self)
    }
}
