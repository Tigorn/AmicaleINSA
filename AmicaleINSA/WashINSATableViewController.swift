//
//  ProxyWashTableViewController.swift
//  ProxiWashINSA
//
//  Created by Arthur Papailhau on 27/03/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import SwiftSpinner
import SWRevealViewController
import SwiftyJSON
import Alamofire
import MBProgressHUD
import SCLAlertView
import Firebase

class WashINSATableViewController: UITableViewController {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    var myActivityIndicator: UIActivityIndicatorView!
    
    let LOG = false
    
    var machines = [machine]()
    
    var machine1 = machine(type: "", available: "", remainingTime: "", avancement: "", startTime: "", endTime: "", numberMachine: "", typeTextile: "")
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
    
    
    var timer = Timer()
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
    
    fileprivate let tableController = UITableViewController()
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
        
        self.refreshControl?.addTarget(self, action: #selector(WashINSATableViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        
        loadInfoInMachinesDB()
    }
    
    func refresh(_ sender:AnyObject) {
        loadInfoInMachinesDB()
    }
    
    func endRefresh(){
        SwiftSpinner.hide()
        let message = "Problème de chargement"
        let myActivityIndicatorHUD = MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
        myActivityIndicatorHUD?.mode = MBProgressHUDMode.indeterminate
        myActivityIndicatorHUD?.labelText = message
        myActivityIndicatorHUD?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(WashINSATableViewController.tapToCancel)))
        self.refreshControl!.endRefreshing()
    }
    
    @IBAction func refreshButtonItemAction(_ sender: AnyObject) {
        loadInfoInMachinesDB()
    }
    
    
    func initActivityIndicator() {
        myActivityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0,y: 0, width: 50, height: 50)) as UIActivityIndicatorView
        myActivityIndicator.center = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
        myActivityIndicator.hidesWhenStopped = true
        myActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
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
        Alamofire.request(url).validate().responseJSON { (response) in
            switch response.result {
            case .success:
                self.observeCountWashingTotal()
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
                        self.animateRows()
                    } else {
                        SwiftSpinner.hide()
                        let message = json_full["message"].string
                        let myActivityIndicatorHUD = MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
                        myActivityIndicatorHUD?.mode = MBProgressHUDMode.indeterminate
                        myActivityIndicatorHUD?.labelText = message
                        myActivityIndicatorHUD?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(WashINSATableViewController.tapToCancel)))
                    }
                }
            case .failure(let error):
                print("Error: \(error)")
                SwiftSpinner.hide()
                let myActivityIndicatorHUD = MBProgressHUD.showAdded(to: self.navigationController?.view, animated: true)
                myActivityIndicatorHUD?.mode = MBProgressHUDMode.determinate
                myActivityIndicatorHUD?.labelText = "Error..."
                myActivityIndicatorHUD?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(WashINSATableViewController.tapToCancel)))
            }
        }
    }
    
    fileprivate func animateRows() {
        
        animateRow(atPosition: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.animateRow(atPosition: 1)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.animateRow(atPosition: 2)
        })
    }
    
    fileprivate func animateRow(atPosition position: Int) {
        let indexPath = IndexPath(item: position, section: 0)
        let contentView = tableView.cellForRow(at: indexPath)?.contentView
        let original = contentView?.frame
        var bounceOffset = original
        bounceOffset?.origin.x -= 100
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            contentView?.frame = bounceOffset!
        }) { (_) in
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                contentView?.frame = original!
            }, completion: nil)}
    }
    
    fileprivate func observeCountWashingTotal() {
        let washingRef = FirebaseManager.firebaseManager.createWashingRef()
        let numberUsersWashingRef = washingRef.child("numberUsers")
        numberUsersWashingRef.observe(.value, with: { (snapshot: FIRDataSnapshot!) in
            if let count = snapshot.value {
                self.title = "WashINSA (\(count))"
            } else {
                self.title = "WashINSA"
            }
        })
    }
    
    
    func tapToCancel(){
        print("cancel tap")
        MBProgressHUD.hideAllHUDs(for: self.navigationController?.view, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! WashINSATableViewCell
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        
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
            if machines[indexInArray].available.contains("Disponible") {
                cell.availabilityMachineLabel.text = machines[indexInArray].available
                cell.availableInTimeMachineLabel.text = ""
                cell.startEndTimeLabel.text = ""
                cell.numberMachineLabel.backgroundColor = UIColor.green
            } else if machines[indexInArray].available.contains("Terminé") {
                cell.availabilityMachineLabel.text = machines[indexInArray].available
                cell.startEndTimeLabel.text = ""
                cell.availableInTimeMachineLabel.text = messageMachineDone
                cell.numberMachineLabel.backgroundColor = UIColor.yellow
            } else if machines[indexInArray].available.contains("Hors service") {
                cell.availabilityMachineLabel.text = "HORS SERVICE"
                cell.availableInTimeMachineLabel.text = "Disponible je sais pas quand ..."
                cell.numberMachineLabel.backgroundColor = UIColor.red
                cell.startEndTimeLabel.text = ""
            } else if machines[indexInArray].available.contains("En cours d'utilisation") {
                let remainingTime = machines[indexInArray].remainingTime
                cell.availabilityMachineLabel.text = machines[indexInArray].available
                cell.availableInTimeMachineLabel.text = "Disponible dans \(remainingTime) min"
                cell.numberMachineLabel.backgroundColor = UIColor.red
                cell.startEndTimeLabel.text = "\(machines[indexInArray].startTime) - \(machines[indexInArray].endTime)"
                if let minute = Int(remainingTime) {
                    if minute == 0 {
                        cell.availabilityMachineLabel.text = machines[indexInArray].available
                        cell.startEndTimeLabel.text = ""
                        cell.availableInTimeMachineLabel.text = messageMachineDone
                        cell.numberMachineLabel.backgroundColor = UIColor.yellow
                    }
                }
            }
            if alreadyNotificationForMachine(indexInArray) {
                cell.reservedMachineCircularLabel.backgroundColor = UIColor.red
                cell.reservedMachineCircularLabel.layer.borderColor = UIColor.black.cgColor
            } else {
                cell.reservedMachineCircularLabel.backgroundColor = UIColor.white
                cell.reservedMachineCircularLabel.layer.borderColor = UIColor.white.cgColor
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
            cell.numberMachineLabel.backgroundColor = UIColor.white
            cell.reservedMachineCircularLabel.backgroundColor = UIColor.white
            cell.reservedMachineCircularLabel.layer.borderColor = UIColor.white.cgColor
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var indexInArray = indexPath.row
        if indexPath.section == 1 {
            indexInArray += 3
        }
        let remainingTime = machines[indexInArray].remainingTime
        var alarm: UITableViewRowAction!
        if alreadyNotificationForMachine(indexInArray) {
            alarm = UITableViewRowAction(style: .normal, title: "Unset\nAlarm") { action, index in
                print("alarm button tapped")
                self.cancelNotificationForMachine(indexInArray)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.left)
                alarm.backgroundColor = UIColor.red
            }
            alarm.backgroundColor = UIColor.red
        } else {
            alarm = UITableViewRowAction(style: .normal, title: "Set\nAlarm") { action, index in
                if let minute = Int(remainingTime) {
                    self.createAndShowAlarmAlert(minute, indexInArray: indexInArray, remainingTimeString: remainingTime, indexPath: indexPath)
                }
            }
            alarm.backgroundColor = UIColor.red
        }
        print("ok 3 - set alarm in row actions")
        return [alarm]
    }
    
    func createAndShowAlarmAlert(_ minute: Int, indexInArray: Int, remainingTimeString: String, indexPath: IndexPath) {
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue-Bold", size: 18)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 16)!,
            kButtonFont: UIFont(name: "HelveticaNeue", size: 16)!,
            showCloseButton: false
        )
        
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("à l'heure") {
            print("compris's button tapped")
            sendLocalNotificationWashingMachine(minute, numeroMachine: indexInArray, numberOfMinutesBeforeTheEndOfTheMachine: 0)
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.left)
        }
        if minute > 5 {
            alert.addButton("5 minutes avant") {
                print("compris's button tapped")
                sendLocalNotificationWashingMachine(minute, numeroMachine: indexInArray, numberOfMinutesBeforeTheEndOfTheMachine: 5)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.left)
            }
        }
        if minute > 10 {
            alert.addButton("10 minutes avant") {
                print("compris's button tapped")
                sendLocalNotificationWashingMachine(minute, numeroMachine: indexInArray, numberOfMinutesBeforeTheEndOfTheMachine: 10)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.left)
            }
        }
        alert.addButton("Annuler") {
            print("cancal's button tapped")
            self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.none)
        }
        alert.showInfo("Disponible dans \(remainingTimeString) min", subTitle: "Je veux être alerté")
    }
    
    
    func cancelNotificationForMachine(_ machineNumber:Int) {
        print("canceled notification for machine \(machineNumber+1)")
        let app:UIApplication = UIApplication.shared
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
    
    func alreadyNotificationForMachine(_ machineNumber: Int) -> Bool {
        _log_Title("WashINSA Notification", location: "WashINSA.alreadyNotificationForMachine()", shouldLog: self.LOG)
        let app:UIApplication = UIApplication.shared
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Seche linge"
        case 1:
            return "Lave linge"
        default:
            return "WashINSA"
        }
    }
    
    func matchesForRegexInText(_ regex: String!, text: String!) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let results = regex.matches(in: text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        var indexInArray = indexPath.row
        if indexPath.section == 1 {
            indexInArray += 3
        }
        if machines[indexInArray].available.contains("En cours d'utilisation") {
            return true
        } else {
            return false
        }
    }
}
