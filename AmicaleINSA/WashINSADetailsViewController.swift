//
//  WashINSADetailsViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 27/03/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import MBCircularProgressBar

class WashINSADetailsViewController: UIViewController {

    @IBOutlet weak var typeMachineLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    
    @IBOutlet weak var circularProgressBar: MBCircularProgressBarView!
    
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
    
    var machineInfo = machine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    func initUI() {
    }
    
    func initCircularProgressBar(){
        if machineInfo.avancement != "" {
            if let avancementFloat = Float(machineInfo.avancement) {
                circularProgressBar.setValue(CGFloat(avancementFloat), animateWithDuration: 1)
            } else {
                circularProgressBar.setValue(0, animateWithDuration: 1)
            }
        } else {
            circularProgressBar.setValue(100, animateWithDuration: 1)
        }
        print("Avancement = \(machineInfo.avancement)")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        //circularProgressBar.setValue(76, animateWithDuration: 1)
        //initCircularProgressBar()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
