//
//  MenuController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import Firebase

protocol MenuControllerDelegate  { 
    func dismissKeyboardFromMenu(_: MenuController)
}

class MenuController: UITableViewController {
    
    @IBOutlet weak var topViewMenu: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameChatLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    var delegate : MenuControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateUI()
        delegate?.dismissKeyboardFromMenu(self)
    }
    
    private func updateUI() {
        usernameChatLabel.text = getUsernameChat()
        profileImageView.image = getProfilPicture()
        temperatureLabel.text = getTemperature()
    }
    
    
    private func initUI() {
        profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        profileImageView.layer.borderWidth = 0.5
        profileImageView.layer.borderColor =   UIColor.blackColor().CGColor
        profileImageView.clipsToBounds = true
        UIGraphicsBeginImageContext(self.topViewMenu.frame.size)
        let image: UIImage = UIImage(named: "redGradient3")!
        image.drawInRect(self.topViewMenu.bounds)
        UIGraphicsEndImageContext()
        topViewMenu.backgroundColor = UIColor(patternImage: image)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!)
    {
        if(segue.identifier == "GoToChat")
        {
            super.prepareForSegue(segue, sender: sender)
            let navVc = segue.destinationViewController as! UINavigationController
            let chatVc = navVc.viewControllers.first as! ChatViewController
            let uuid = UIDevice.currentDevice().identifierForVendor!.UUIDString
            //let rand = Int(arc4random_uniform(UInt32(100)))
            //chatVc.senderId = "\(uuid.md5())\(rand)"
            //chatVc.senderId = getUsernameChat()
            
            /* ça c'est pas bon parce qu'il faut faire la diff entre plusieurs pseudos, */
            chatVc.senderId = "\(uuid.md5())"
            chatVc.senderDisplayName = getUsernameChat()
            print("Sender display name: \(chatVc.senderDisplayName)")
            delegate = chatVc
        } else if (segue.identifier == "GoToSettings"){
            let navVc = segue.destinationViewController as! UINavigationController
            let settingsTVc = navVc.viewControllers.first as! SettingsTableViewController
            delegate = settingsTVc
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table virew data source

    /* override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    } */

    
    /* override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    } */

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

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
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Cell selected: \(indexPath.row)")
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
