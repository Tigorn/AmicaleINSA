//
//  ProxyWashTableViewController.swift
//  ProxiWashINSA
//
//  Created by Arthur Papailhau on 27/03/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import Fuzi
import SwiftSpinner
import SWRevealViewController
import SwiftyJSON
import Alamofire
import MBProgressHUD
import SCLAlertView

class WashINSATableViewController: UITableViewController {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    var myActivityIndicator: UIActivityIndicatorView!
    
    
    
    var machines = [machine]()
    
    var machine1 = machine(type: "Chargement en cours ...", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine2 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine3 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine4 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine5 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine6 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine7 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine8 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine9 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine10 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine11 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    var machine12 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
    
    
    var timer = NSTimer()
    var dataLoaded = false
    
    struct machine {
        var type = ""
        var available = ""
        var remainingTime = ""
        var avancement = ""
        var startTime = ""
        var endTime = ""
        var numberMachine = ""
        var typeTextile = ""
    }
    
    private let tableController = UITableViewController()
    var messageMachineDone = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        machines = [machine1, machine2, machine3, machine3, machine4, machine5, machine6, machine7, machine8, machine9, machine10, machine11, machine12]
        
        initUI()
        
        self.refreshControl?.addTarget(self, action: #selector(WashINSATableViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        loadInfoInMachinesDB()
    }
    
    func refresh(sender:AnyObject) {
        loadInfoInMachinesDB()
    }
    
    func endRefresh(){
        SwiftSpinner.hide()
        let message = "Problème de chargement"
        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
        myActivityIndicatorHUD.labelText = message
        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(WashINSATableViewController.tapToCancel)))
        self.refreshControl!.endRefreshing()
    }
    
    @IBAction func refreshButtonItemAction(sender: AnyObject) {
        loadInfoInMachinesDB()
    }
    
    
    func initActivityIndicator() {
        myActivityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0, 50, 50)) as UIActivityIndicatorView
        myActivityIndicator.center = CGPoint(x: UIScreen.mainScreen().bounds.width/2, y: UIScreen.mainScreen().bounds.height/2)
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(myActivityIndicator)
    }
    
    func initUI(){
    }
    
    func loadInfoInMachinesDB(){
        let url = Public.urlWashINSAAPI
        var indexMachine = 0
        SwiftSpinner.show("Connexion \nen cours...").addTapHandler({
            SwiftSpinner.hide()
        })
        Alamofire.request(.GET, url).validate().responseJSON { response in
            switch response.result {
            case .Success:
                print("response = \(response)")
                if let value = response.result.value {
                    let json_full = JSON(value)
                    let errorCode = json_full["errorCode"].int
                    if let messageMachineDoneString = json_full["messageMachineTermine"].string {
                        self.messageMachineDone = messageMachineDoneString
                    }
                    if errorCode != -1 {
                        let json = json_full["json"]
                        for (key,subJson):(String, JSON) in json {
                            print("key = \(key), subJson = \(subJson)")
                            if let machine = subJson["machine"].int {
                                self.machines[indexMachine].numberMachine = "n° \(machine)"
                                print("number machine = \(machine)")
                            }
                            if let available = subJson["available"].string {
                                self.machines[indexMachine].available = available
                            }
                            if let start = subJson["start"].string {
                                self.machines[indexMachine].startTime = start
                            }
                            if let end = subJson["end"].string {
                                self.machines[indexMachine].endTime = end
                            }
                            if let remainingTime = subJson["remainingTime"].string {
                                self.machines[indexMachine].remainingTime = remainingTime
                            }
                            if let type = subJson["type"].string {
                                self.machines[indexMachine].type = type
                            }
                            indexMachine += 1
                        }
                        self.dataLoaded = true
                        self.tableView.reloadData()
                        SwiftSpinner.hide()
                        self.refreshControl!.endRefreshing()
                    } else {
                        SwiftSpinner.hide()
                        let message = json_full["message"].string
                        let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
                        myActivityIndicatorHUD.mode = MBProgressHUDMode.Indeterminate
                        myActivityIndicatorHUD.labelText = message
                        myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(WashINSATableViewController.tapToCancel)))
                    }
                }
            case .Failure(let error):
                print("Error: \(error)")
                SwiftSpinner.hide()
                let myActivityIndicatorHUD = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
                myActivityIndicatorHUD.mode = MBProgressHUDMode.Determinate
                myActivityIndicatorHUD.labelText = "Error..."
                myActivityIndicatorHUD.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(WashINSATableViewController.tapToCancel)))
            }
        }
    }
    
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDsForView(self.navigationController?.view, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return 3
        case 1:
            return 9
        default:
            return 1
        }
    }
    
    func RBResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! WashINSATableViewCell
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        if dataLoaded == true {
            
            var indexInArray = indexPath.row
            if indexPath.section == 1 {
                indexInArray += 3
            }
            cell.numberMachineLabel.layer.cornerRadius = cell.numberMachineLabel.frame.size.width/2
            cell.numberMachineLabel.layer.borderWidth = 0.5
            cell.numberMachineLabel.clipsToBounds = true
            
            /* Reserved machine */
            cell.reservedMachineCircularLabel.layer.cornerRadius = cell.reservedMachineCircularLabel.frame.size.width/2
            cell.reservedMachineCircularLabel.layer.borderWidth = 0.5
            cell.reservedMachineCircularLabel.clipsToBounds = true
            cell.reservedMachineCircularLabel.text = ""
            
            cell.numberMachineLabel.text = machines[indexInArray].numberMachine
            cell.typeMachineLabel.text = machines[indexInArray].type
            if machines[indexInArray].available.containsString("Disponible") {
                cell.availabilityMachineLabel.text = machines[indexInArray].available
                cell.availableInTimeMachineLabel.text = ""
                cell.startEndTimeLabel.text = ""
                cell.numberMachineLabel.backgroundColor = UIColor.greenColor()
            } else if machines[indexInArray].available.containsString("Terminé") {
                cell.availabilityMachineLabel.text = machines[indexInArray].available
                cell.startEndTimeLabel.text = ""
                cell.availableInTimeMachineLabel.text = messageMachineDone
                cell.numberMachineLabel.backgroundColor = UIColor.yellowColor()
            } else if machines[indexInArray].available.containsString("Hors service") {
                cell.availabilityMachineLabel.text = "HORS SERVICE"
                cell.availableInTimeMachineLabel.text = "Disponible je sais pas quand ..."
                cell.numberMachineLabel.backgroundColor = UIColor.redColor()
                cell.startEndTimeLabel.text = ""
            } else if machines[indexInArray].available.containsString("En cours d'utilisation") {
                cell.availabilityMachineLabel.text = machines[indexInArray].available
                cell.availableInTimeMachineLabel.text = "Disponible dans \(machines[indexInArray].remainingTime) min"
                cell.numberMachineLabel.backgroundColor = UIColor.redColor()
                cell.startEndTimeLabel.text = "\(machines[indexInArray].startTime) - \(machines[indexInArray].endTime)"
            }
            if alreadyNotificationForMachine(indexInArray) {
                cell.reservedMachineCircularLabel.backgroundColor = UIColor.redColor()
                cell.reservedMachineCircularLabel.layer.borderColor = UIColor.blackColor().CGColor
            } else {
                cell.reservedMachineCircularLabel.backgroundColor = UIColor.whiteColor()
                cell.reservedMachineCircularLabel.layer.borderColor = UIColor.whiteColor().CGColor
            }
        } else {
            cell.numberMachineLabel.text = ""
            cell.startEndTimeLabel.text = "Loading..."
            cell.typeMachineLabel.text = ""
            cell.availableInTimeMachineLabel.text = ""
            cell.availabilityMachineLabel.text = ""
            cell.numberMachineLabel.layer.cornerRadius = cell.numberMachineLabel.frame.size.width/2
            cell.numberMachineLabel.layer.borderWidth = 0.5
            cell.numberMachineLabel.clipsToBounds = true
            cell.numberMachineLabel.backgroundColor = UIColor.whiteColor()
            cell.reservedMachineCircularLabel.backgroundColor = UIColor.whiteColor()
            cell.reservedMachineCircularLabel.layer.borderColor = UIColor.whiteColor().CGColor
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var indexInArray = indexPath.row
        if indexPath.section == 1 {
            indexInArray += 3
        }
        let remainingTime = machines[indexInArray].remainingTime
        var minuteString = "minutes"
        var alarm: UITableViewRowAction!
        if alreadyNotificationForMachine(indexInArray) {
            alarm = UITableViewRowAction(style: .Normal, title: "Unset\nAlarm") { action, index in
                print("alarm button tapped")
                self.cancelNotificationForMachine(indexInArray)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                alarm.backgroundColor = UIColor.redColor()
            }
            alarm.backgroundColor = UIColor.redColor()
        } else {
            alarm = UITableViewRowAction(style: .Normal, title: "Set\nAlarm") { action, index in
                print("alarm button tapped")
                if let minute = Int(remainingTime) {
                    if minute < 2 {
                        minuteString = "minute"
                    }
                    sendLocalNotificationWashingMachine(minute, numeroMachine: indexInArray)
                }
                let appearance = SCLAlertView.SCLAppearance(
                    showCloseButton: false
                )
                let alert = SCLAlertView(appearance: appearance)
                alert.addButton("Compris !") {
                    print("compris's button tapped")
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                }
                alert.showInfo("Alarme laverie", subTitle: "Vous allez recevoir une notification dans \(remainingTime) \(minuteString) pour vous rappeler que vous devez aller chercher votre linge !")
            }
            alarm.backgroundColor = UIColor.redColor()
        }
        return [alarm]
    }
    
    func cancelNotificationForMachine(machineNumber:Int) {
        print("canceled notification for machine \(machineNumber+1)")
        let app:UIApplication = UIApplication.sharedApplication()
        for oneEvent in app.scheduledLocalNotifications! {
            let notification = oneEvent as UILocalNotification
            if let userInfoCurrent = notification.userInfo as? [String:Int] {
                if let number = userInfoCurrent["numero_machine"] {
                    if number == machineNumber {
                        app.cancelLocalNotification(notification)
                    }
                }
            }
        }
    }
    
    func alreadyNotificationForMachine(machineNumber: Int) -> Bool {
        let app:UIApplication = UIApplication.sharedApplication()
        for oneEvent in app.scheduledLocalNotifications! {
            let notification = oneEvent as UILocalNotification
            if let userInfoCurrent = notification.userInfo as? [String:Int] {
                if let number = userInfoCurrent["numero_machine"] {
                    if number == machineNumber {
                        //app.cancelLocalNotification(notification)
                        print("machine number: \(machineNumber+1) exists for notification")
                        return true
                    }
                }
            }
        }
        print("machine number: \(machineNumber+1) does not exist for notification")
        return false
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {}
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Seche linge"
        case 1:
            return "Lave linge"
        default:
            return "WashINSA"
        }
    }
    
    func matchesForRegexInText(regex: String!, text: String!) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substringWithRange($0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        var indexInArray = indexPath.row
        if indexPath.section == 1 {
            indexInArray += 3
        }
        if machines[indexInArray].available.containsString("En cours d'utilisation") {
            return true
        } else {
            return false
        }
    }
}