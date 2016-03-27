//
//  ProxyWashTableViewController.swift
//  ProxiWashINSA
//
//  Created by Arthur Papailhau on 27/03/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import Fuzi

class WashINSATableViewController: UITableViewController {
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    
    var machines = [machine]()
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        loadInfoInMachinesDB()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func loadInfoInMachinesDB(){
        
        let myURLString = Storyboard.urlProxyWash
        guard let myURL = NSURL(string: myURLString) else {
            print("Error: \(myURLString) doesn't seem to be a valid URL")
            return
        }
        
        do {
            /*
             1: Type de machine
             2: DISPONIBLE ou pas, dans <font>
             */
            let myHTMLString = try String(contentsOfURL: myURL, encoding: NSUTF8StringEncoding)
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
                
                let doc = try HTMLDocument(string: myHTMLString, encoding: NSUTF8StringEncoding)
                
                for listeMachines in doc.xpath("//td[@style=\"height:10;vertical-align:middle\"]") {
                    
                    if let infoMachineTypeOrNumero = listeMachines.firstChild(xpath: "text()") {
                        infoMachineTypeOrNumeroString = infoMachineTypeOrNumero.description
                        
                        let matchesTime = matchesForRegexInText("[0-9][0-9]?:[0-9][0-9]", text: infoMachineTypeOrNumeroString)
                        
                        if infoMachineTypeOrNumeroString.containsString("SECHE") || infoMachineTypeOrNumeroString.containsString("LAVE") {
                            type = infoMachineTypeOrNumeroString
                            print("type = \(type)")
                            indexMachine += 1
                            machines.append(machine())
                            machines[indexMachine].type = type
                        } else if infoMachineTypeOrNumeroString.containsString("No") && matchesForRegexInText("No\\s+[0-9]+", text: infoMachineTypeOrNumeroString).count != 0  {
                            numberMachine = infoMachineTypeOrNumeroString
                            print("numero machine = \(numberMachine)")
                            machines[indexMachine].numberMachine = numberMachine
                        } else if (matchesTime.count != 0){
                            if state == 0 {
                                state = 1
                                startTime = matchesTime[0]
                                print("debut = \(startTime)")
                                machines[indexMachine].startTime = startTime
                            } else if state == 1 {
                                state = 0
                                endTime = matchesTime[0]
                                print("fin = \(endTime)")
                                machines[indexMachine].endTime = endTime
                            }
                        }
                        else {
                            typeTextile = infoMachineTypeOrNumeroString
                            print("type textile = \(typeTextile)")
                            machines[indexMachine].typeTextile = typeTextile
                        }
                    }
                    
                    if let availableMachine = listeMachines.firstChild(xpath: "font/text()") {
                        available = availableMachine.description
                        print("available = \(available)")
                        machines[indexMachine].available = available
                    }
                    
                    if let avancementMachine = listeMachines.firstChild(xpath: "table//td")?.attr("width") {
                        avancement = avancementMachine
                        print("avancement en % : \(avancement)")
                        machines[indexMachine].avancement = avancement
                    }
                    
                    // temps restant
                    if let remainingTimeMachine = listeMachines.firstChild(xpath: "table")?.attr("title") {
                        remainingTime = remainingTimeMachine
                        let matchesRemainingTime = matchesForRegexInText("[0-9][0-9]?", text: remainingTime)
                        remainingTime = matchesRemainingTime[0]
                        print("remaning time = \(remainingTime) min")
                        machines[indexMachine].remainingTime = remainingTime
                    }
                }
                
            } catch let error {
                print(error)
            }
            
        } catch let error as NSError {
            print("Error: \(error)")
        }
        print(machines.description)
        

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
        
        // Configure the cell...
        
        var indexInArray = indexPath.row
        
        if indexPath.section == 1 {
            //cell.numberMachineLabel.backgroundColor = UIColor.redColor()
            indexInArray += 3
        }
        //        } else if indexPath.section == 0 {
        //            //cell.numberMachineLabel.backgroundColor = UIColor.blueColor()
        //        }
        cell.numberMachineLabel.layer.cornerRadius = cell.numberMachineLabel.frame.size.width/2
        cell.numberMachineLabel.layer.borderWidth = 0.5
        cell.numberMachineLabel.clipsToBounds = true
        
        cell.numberMachineLabel.text = machines[indexInArray].numberMachine
        cell.typeMachineLabel.text = machines[indexInArray].type
        
        if machines[indexInArray].available.containsString("DISPONIBLE") {
            cell.availabilityMachineLabel.text = "DISPONIBLE"
            cell.availableInTimeMachineLabel.text = ""
            cell.numberMachineLabel.backgroundColor = UIColor.greenColor()
        } else if machines[indexInArray].available.containsString("TERMINE") {
            cell.availabilityMachineLabel.text = "TERMINE"
            cell.numberMachineLabel.backgroundColor = UIColor.yellowColor()
            cell.availableInTimeMachineLabel.text = "Quelqu'un vous attend ..."
        }
        else {
            cell.availabilityMachineLabel.text = "En cours d'utilisation"
            cell.availableInTimeMachineLabel.text = "Disponible dans \(machines[indexInArray].remainingTime) min"
            cell.numberMachineLabel.backgroundColor = UIColor.redColor()
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
