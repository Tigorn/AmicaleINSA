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
        
        
        
        
//        refreshView = BreakOutToRefreshView(scrollView: tableView)
//        refreshView.delegate = self
//        tableView.addSubview(refreshView)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func refresh(sender:AnyObject)
    {
        loadInfoInMachinesDB()
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
        //initActivityIndicator()
        //tableView.allowsSelection = false
    }
    
    func loadInfoInMachinesDB(){
        let qos = Int(QOS_CLASS_USER_INITIATED.rawValue) // qos = quality of service (if it's slow, important...)
        SwiftSpinner.show("Connexion \nen cours...").addTapHandler({
            SwiftSpinner.hide()
        })
        let myURLString = Storyboard.urlProxyWash
        guard let myURL = NSURL(string: myURLString) else {
            print("Error: \(myURLString) doesn't seem to be a valid URL")
            return
        }
        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
        do {
            /*
             1: Type de machine
             2: DISPONIBLE ou pas, dans <font>
             */
            
            print(">>> DEBUG 1")
            let myHTMLString = try String(contentsOfURL: myURL, encoding: NSUTF8StringEncoding)
            print(">>> DEBUG 2")
            do {
                var type = ""
                var available = ""
                var remainingTime = ""
                var avancement = ""
                var startTime = ""
                var endTime = ""
                var state = 0 // 0 : type machine, 1: numero machine:
                var numberMachine = ""
                var infoMachineTypeOrNumeroString = ""
                var typeTextile = ""
                
                var indexMachine = -1
                
                self.machines = []
                
                let doc = try HTMLDocument(string: myHTMLString, encoding: NSUTF8StringEncoding)
                
                for listeMachines in doc.xpath("//td[@style=\"height:10;vertical-align:middle\"]") {
                    
                    if let infoMachineTypeOrNumero = listeMachines.firstChild(xpath: "text()") {
                        infoMachineTypeOrNumeroString = infoMachineTypeOrNumero.description
                        
                        let matchesTime = self.matchesForRegexInText("[0-9][0-9]?:[0-9][0-9]", text: infoMachineTypeOrNumeroString)
                        
                        if infoMachineTypeOrNumeroString.containsString("SECHE") || infoMachineTypeOrNumeroString.containsString("LAVE") {
                            type = infoMachineTypeOrNumeroString
                            print("type = \(type)")
                            indexMachine += 1
                            self.machines.append(machine())
                            self.machines[indexMachine].type = type
                        } else if infoMachineTypeOrNumeroString.containsString("No") && self.matchesForRegexInText("No\\s+[0-9]+", text: infoMachineTypeOrNumeroString).count != 0  {
                            numberMachine = infoMachineTypeOrNumeroString
                            print("numero machine = \(numberMachine)")
                            self.machines[indexMachine].numberMachine = numberMachine
                        } else if (matchesTime.count != 0){
                            if state == 0 {
                                state = 1
                                startTime = matchesTime[0]
                                print("debut = \(startTime)")
                                self.machines[indexMachine].startTime = startTime
                            } else if state == 1 {
                                state = 0
                                endTime = matchesTime[0]
                                print("fin = \(endTime)")
                                self.machines[indexMachine].endTime = endTime
                            }
                        }
                        else {
                            typeTextile = infoMachineTypeOrNumeroString
                            print("type textile = \(typeTextile)")
                            self.machines[indexMachine].typeTextile = typeTextile
                        }
                    }
                    
                    if let availableMachine = listeMachines.firstChild(xpath: "font/text()") {
                        available = availableMachine.description
                        print("available = \(available)")
                        self.machines[indexMachine].available = available
                    }
                    
                    if let avancementMachine = listeMachines.firstChild(xpath: "table//td")?.attr("width") {
                        print(self.matchesForRegexInText("[0-9]+(\\.[0-9][0-9]?)?", text: avancementMachine))
                        avancement = self.matchesForRegexInText("[0-9]+(\\.[0-9][0-9]?)?", text: avancementMachine)[0]
                        print("avancement en % : \(avancement)")
                        self.machines[indexMachine].avancement = avancement
                    }
                    
                    // temps restant
                    if let remainingTimeMachine = listeMachines.firstChild(xpath: "table")?.attr("title") {
                        remainingTime = remainingTimeMachine
                        let matchesRemainingTime = self.matchesForRegexInText("[0-9][0-9]?", text: remainingTime)
                        remainingTime = matchesRemainingTime[0]
                        print("remaning time = \(remainingTime) min")
                        self.machines[indexMachine].remainingTime = remainingTime
                    }
                }
                
            } catch let error {
                print(error)
            }
            
        } catch let error as NSError {
            print("Error: \(error)")
        }
        //print(machines.description)
        dispatch_async(dispatch_get_main_queue(), {
        self.dataLoaded = true
        self.tableView.reloadData()
        SwiftSpinner.hide()
        self.refreshControl!.endRefreshing()
            })
        }
        
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
            
            cell.numberMachineLabel.text = machines[indexInArray].numberMachine
            cell.typeMachineLabel.text = machines[indexInArray].type
            
            if machines[indexInArray].available.containsString("DISPONIBLE") {
                cell.availabilityMachineLabel.text = "DISPONIBLE"
                cell.availableInTimeMachineLabel.text = ""
                cell.startEndTimeLabel.text = ""
                cell.numberMachineLabel.backgroundColor = UIColor.greenColor()
            } else if machines[indexInArray].available.containsString("TERMINE") {
                cell.availabilityMachineLabel.text = "TERMINE"
                cell.startEndTimeLabel.text = ""
                cell.numberMachineLabel.backgroundColor = UIColor.yellowColor()
                cell.availableInTimeMachineLabel.text = "Quelqu'un vous attend ..."
            }
            else {
                cell.availabilityMachineLabel.text = "En cours d'utilisation"
                cell.availableInTimeMachineLabel.text = "Disponible dans \(machines[indexInArray].remainingTime) min"
                cell.numberMachineLabel.backgroundColor = UIColor.redColor()
                cell.startEndTimeLabel.text = "\(machines[indexInArray].startTime) - \(machines[indexInArray].endTime)"
            }
        } else {
            cell.numberMachineLabel.text = ""
            cell.typeMachineLabel.text = ""
            cell.availableInTimeMachineLabel.text = ""
            cell.availabilityMachineLabel.text = ""
            cell.numberMachineLabel.layer.cornerRadius = cell.numberMachineLabel.frame.size.width/2
            cell.numberMachineLabel.layer.borderWidth = 0.5
            cell.numberMachineLabel.clipsToBounds = true
            cell.numberMachineLabel.backgroundColor = UIColor.whiteColor()
        }
        return cell
    }
    
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
    
    //    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    //        let detailVC = segue.destinationViewController as! ProxyWashDetailsViewController
    //
    //        // Pass the selected object to the destination view controller.
    //        if let indexPath = self.tableView.indexPathForSelectedRow {
    //            var indexInArray = 0
    //            let row = Int(indexPath.row)
    //            if indexPath.section == 1 {
    //                //cell.numberMachineLabel.backgroundColor = UIColor.redColor()
    //                indexInArray += 3
    //            }
    //            detailVC.machineInfo.type = machines[row].type
    //            //detailScene.currentObject = (objects?[row] as! PFObject)
    //        }
    //    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    
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
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
//     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        let detailVC = segue.destinationViewController as! WashINSADetailsViewController
//        
//        if let indexPath = self.tableView.indexPathForSelectedRow {
//            let row = Int(indexPath.row)
//            var indexInArray = row
//            if indexPath.section == 1 {
//                indexInArray += 3
//            }
//            detailVC.machineInfo.type = "\(machines[indexInArray].numberMachine) \(machines[indexInArray].type)"
//            detailVC.machineInfo.avancement = machines[indexInArray].avancement
//            detailVC.machineInfo.startTime = machines[indexInArray].startTime
//            detailVC.machineInfo.endTime = machines[indexInArray].endTime
//            print("avancement[row] = \(machines[indexInArray].avancement)")
//        }
//
//     }
}