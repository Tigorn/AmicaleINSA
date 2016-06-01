//
//  LocalINSATableViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 20/05/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import SWRevealViewController
import SwiftSpinner
import SwiftyJSON
import Alamofire
import MBProgressHUD

class LocalINSATableViewController: UITableViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    struct local {
        var name = ""
        var available = ""
        var remainingTime = -1
        var startTime = ""
        var endTime = ""
    }
    var locals = [local]()
    var AmicaleLocal = local(name: "Amicale", available: "Ouvert", remainingTime: -1, startTime: "", endTime: "")
    var PtitKawaLocal = local(name: "P'tit kawa", available: "Fermé", remainingTime: -1, startTime: "", endTime: "")
    var ProximoLocal = local(name: "Proximo", available: "Fermé ...", remainingTime: -1, startTime: "", endTime: "")
    var ClubALocal = local(name: "Club A", available: "Ouvert", remainingTime: -1, startTime: "", endTime: "")
    var ClubBLocal = local(name: "Club B", available: "Ouvert", remainingTime: -1, startTime: "", endTime: "")
    var ClubCLocal = local(name: "Club C", available: "Ouvert", remainingTime: -1, startTime: "", endTime: "")
    var messageIfIWant = ""
    var dataLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        fillInitialDBLocals()
        
        //self.refreshControl?.addTarget(self, action: #selector(LocalINSATableViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        //loadInfoInLocalsDB()
        
        self.tableView.reloadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
//    func refresh(sender:AnyObject)
//    {
//        loadInfoInLocalsDB()
//    }
    
    func fillInitialDBLocals() {
        locals = [AmicaleLocal, PtitKawaLocal, ProximoLocal, ClubALocal, ClubBLocal, ClubCLocal]
    }
//    
//    func loadInfoInLocalsDB(){
//        let url = Public.urlLocalsINSAAPI
//        var indexLocal = 0
//        SwiftSpinner.show("Connexion \nen cours...").addTapHandler({
//            SwiftSpinner.hide()
//        })
//        Alamofire.request(.GET, url).validate().responseJSON { response in
//            switch response.result {
//            case .Success:
//                print("response = \(response)")
//                if let value = response.result.value {
//                    let json_full = JSON(value)
//                    let errorCode = json_full["errorCode"].int
//                    if let messageIfIWantString = json_full["messageIfIWant"].string {
//                        self.messageIfIWant = messageIfIWantString
//                    }
//                    if errorCode != -1 {
//                        let json = json_full["json"]
//                        for (key,subJson):(String, JSON) in json {
//                            print("key = \(key), subJson = \(subJson)")
//                            if let remainingTime = subJson["remainingTime"].int {
//                                self.locals[indexLocal].remainingTime = remainingTime
//                            }
//                            if let available = subJson["available"].string {
//                                self.locals[indexLocal].available = available
//                            }
//                            if let start = subJson["start"].string {
//                                self.locals[indexLocal].startTime = start
//                            }
//                            if let end = subJson["end"].string {
//                                self.locals[indexLocal].endTime = end
//                            }
//                            if let name = subJson["name"].string {
//                                self.locals[indexLocal].name = name
//                            }
//                            indexLocal += 1
//                        }
//                        self.dataLoaded = true
//                        self.tableView.reloadData()
//                        SwiftSpinner.hide()
//                        self.refreshControl!.endRefreshing()
//                    } else {
//                        SwiftSpinner.hide()
//                        let message = json_full["message"].string
//                        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
//                        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
//                        myActivityIndicatorHUD.labelText = message
//                        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocalINSATableViewController.tapToCancel)))
//                    }
//                }
//            case .Failure(let error):
//                print("Error: \(error)")
//                SwiftSpinner.hide()
//                let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
//                myActivityIndicatorHUD.mode = MBProgressHUDMode.Determinate
//                myActivityIndicatorHUD.labelText = "Error..."
//                myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocalINSATableViewController.tapToCancel)))
//            }
//        }
//
//    }
    
//    func endRefresh(){
//        SwiftSpinner.hide()
//        let message = "Problème de chargement"
//        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
//        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
//        myActivityIndicatorHUD.labelText = message
//        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LocalINSATableViewController.tapToCancel)))
//        self.refreshControl!.endRefreshing()
//    }
    
//    func tapToCancel(){
//        print("cancel tap")
//        MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return locals.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifierLocalINSA", forIndexPath: indexPath) as! LocalINSATableViewCell
        //if dataLoaded == true {
            cell.availabilityLocalLabel.text = locals[indexPath.row].available
            cell.nameLocalLabel.text = locals[indexPath.row].name
        ///} else {
        //    cell.availabilityLocalLabel.text = "Loading..."
        //    cell.nameLocalLabel.text = "Loading..."
        //}

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
