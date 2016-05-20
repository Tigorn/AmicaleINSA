//
//  LocalINSATableViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 20/05/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import SWRevealViewController

class LocalINSATableViewController: UITableViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    struct local {
        var name = ""
        var available = ""
        var remainingTime = ""
        var startTime = ""
        var endTime = ""
    }
    var locals = [local]()
    var AmicaleLocal = local(name: "Amicale", available: "Ouvert", remainingTime: "", startTime: "", endTime: "")
    var PtitKawaLocal = local(name: "P'tit kawa", available: "Fermé", remainingTime: "", startTime: "", endTime: "")
    var ProximoLocal = local(name: "Proximo", available: "Fermé ...", remainingTime: "", startTime: "", endTime: "")
    var ClubALocal = local(name: "Club A", available: "Ouvert", remainingTime: "", startTime: "", endTime: "")
    var ClubBLocal = local(name: "Club B", available: "Ouvert", remainingTime: "", startTime: "", endTime: "")
    var ClubCLocal = local(name: "Club C", available: "Ouvert", remainingTime: "", startTime: "", endTime: "")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        fillInitialDBLocals()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func fillInitialDBLocals() {
        locals = [AmicaleLocal, PtitKawaLocal, ProximoLocal, ClubALocal, ClubBLocal, ClubCLocal]
    }

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

        cell.availabilityLocalLabel.text = locals[indexPath.row].available
        cell.nameLocalLabel.text = locals[indexPath.row].name

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
