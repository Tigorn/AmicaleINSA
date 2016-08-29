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
    
    let LOG = false
    
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
                _log_Title("WashINSA", location: "WashINSA.loadInfoInMachinesDB()", shouldLog: self.LOG)
                _log_Element("Response: \(response)", shouldLog: self.LOG)
                _log_FullLineStars(self.LOG)
                if let value = response.result.value {
                    let json_full = JSON(value)
                    let errorCode = json_full["errorCode"].int
                    if let messageMachineDoneString = json_full["messageMachineTermine"].string {
                        self.messageMachineDone = messageMachineDoneString
                    }
                    if errorCode != -1 {
                        let json = json_full["json"]
                        _log_Title("WashINSA", location: "WashINSA.loadInfoInMachinesDB()", shouldLog: self.LOG)
                        for (key,subJson):(String, JSON) in json {
                            _log_Element("Key: \(key)", shouldLog: self.LOG)
                            _log_Element("SubJson: \(subJson)", shouldLog: self.LOG)
                            if let machine = subJson["machine"].int {
                                self.machines[indexMachine].numberMachine = "n° \(machine)"
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
                        _log_FullLineStars(self.LOG)
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
                let remainingTime = machines[indexInArray].remainingTime
                cell.availabilityMachineLabel.text = machines[indexInArray].available
                cell.availableInTimeMachineLabel.text = "Disponible dans \(remainingTime) min"
                cell.numberMachineLabel.backgroundColor = UIColor.redColor()
                cell.startEndTimeLabel.text = "\(machines[indexInArray].startTime) - \(machines[indexInArray].endTime)"
                if let minute = Int(remainingTime) {
                    if minute == 0 {
                        cell.availabilityMachineLabel.text = machines[indexInArray].available
                        cell.startEndTimeLabel.text = ""
                        cell.availableInTimeMachineLabel.text = messageMachineDone
                        cell.numberMachineLabel.backgroundColor = UIColor.yellowColor()
                    }
                }
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
                if let minute = Int(remainingTime) {
                    self.createAndShowAlarmAlert(minute, indexInArray: indexInArray, remainingTimeString: remainingTime, indexPath: indexPath)
                }
            }
            alarm.backgroundColor = UIColor.redColor()
        }
        return [alarm]
    }
    
    func createAndShowAlarmAlert(minute: Int, indexInArray: Int, remainingTimeString: String, indexPath: NSIndexPath) {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false,
            kTitleFont: UIFont(name: "HelveticaNeue-Bold", size: 18)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 16)!,
            kButtonFont: UIFont(name: "HelveticaNeue", size: 16)!
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("à l'heure") {
            print("compris's button tapped")
            sendLocalNotificationWashingMachine(minute, numeroMachine: indexInArray, numberOfMinutesBeforeTheEndOfTheMachine: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
        }
        if minute > 5 {
            alert.addButton("5 minutes avant") {
                print("compris's button tapped")
                sendLocalNotificationWashingMachine(minute, numeroMachine: indexInArray, numberOfMinutesBeforeTheEndOfTheMachine: 5)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
            }
        }
        if minute > 10 {
            alert.addButton("10 minutes avant") {
                print("compris's button tapped")
                sendLocalNotificationWashingMachine(minute, numeroMachine: indexInArray, numberOfMinutesBeforeTheEndOfTheMachine: 10)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
            }
        }
        alert.addButton("Annuler") {
            print("cancal's button tapped")
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
        alert.showInfo("Disponible dans \(remainingTimeString) min", subTitle: "Je veux être alerté")
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
        _log_Title("WashINSA Notification", location: "WashINSA.alreadyNotificationForMachine()", shouldLog: self.LOG)
        let app:UIApplication = UIApplication.sharedApplication()
        _log_Element("Local Notifications: \(app.scheduledLocalNotifications!)", shouldLog: self.LOG)
        for oneEvent in app.scheduledLocalNotifications! {
            let notification = oneEvent as UILocalNotification
            if let userInfoCurrent = notification.userInfo as? [String:Int] {
                if let number = userInfoCurrent["numero_machine"] {
                    if number == machineNumber {
                        print("machine number: \(machineNumber+1) exists for notification")
                        return true
                    }
                }
            }
        }
        _log_Element("Machine number: \(machineNumber+1) does not exist in notification list", shouldLog: self.LOG)
        _log_FullLineStars(self.LOG)
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