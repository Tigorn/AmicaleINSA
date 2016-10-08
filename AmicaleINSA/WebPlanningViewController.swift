//
//  WebPlanningViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 29/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import SwiftSpinner
import SWRevealViewController

class WebPlanningViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var menuButton:UIBarButtonItem!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var ActualBarButtonItem: UIBarButtonItem!
    var weekNumberToday : Int = 0 {
        didSet {
            print("weekNumberToday: \(oldValue) -> \(weekNumberToday)")
        }
    }
    var debug = false
    let offsetScroll = CGFloat(190)
    var AmITheCurrentWeek = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
        }
        
        self.navigationController?.navigationBar.translucent = false
        
        // set delegate
        self.webView.delegate = self
        self.webView.scrollView.delegate = self
        
        weekNumberToday = getWeekNumber()
        print("week number: \(weekNumberToday)")
        let url = NSURL(string: getUrlPlanning(weekNumberToday))
        if url?.absoluteString != Public.noGroupINSA {
            let request = NSURLRequest(URL: url!)
            webView.loadRequest(request)
        } else {
            self.performSegueWithIdentifier(Public.segueFromPlanningToSettings, sender: self)
        }
        
        initUI()
    }
    
    func initUI(){
        ActualBarButtonItem.title = getYearSpeGroupPlanningExpress()
    }
    
    
    func setLandscapeOrientation(){
        let value = UIInterfaceOrientation.LandscapeLeft.rawValue;
        UIDevice.currentDevice().setValue(value, forKey: "orientation")
    }
    
    
    func webViewDidStartLoad(webView: UIWebView) {
        if (debug) {
            print("[WebPlanningViewController][webViewDidStartLoad] I start loading my page")
        }
        SwiftSpinner.show("Connexion \nen cours...").addTapHandler({
            SwiftSpinner.hide()
        })
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        let offSetOfDay = getOffsetOfDay()
        if (debug) {
            print("[WebPlanningViewController][webViewDidFinishLoad] I stop loading my page")
        }
        SwiftSpinner.hide()
        
        self.webView.scrollView.setZoomScale(getZoomValue(), animated: true)
        if debug {
            print("getOffSet: \(offSetOfDay)")
        }
        self.webView.scrollView.contentOffset = CGPointMake(offSetOfDay, 0)
        
    }
    
    func getZoomValue() -> CGFloat {
        if AmITheCurrentWeek {
            let currentLang = Device.CURRENT_LANGUAGE
            let dayOfWeek = getDayOfWeek()
            if (currentLang == "en"){
                if (dayOfWeek == "Saturday") || (dayOfWeek == "Sunday"){
                    return 0
                } else {
                    return 3
                }
            } else {
                if (dayOfWeek == "samedi") || (dayOfWeek == "dimanche"){
                    return 0
                } else {
                    return 3
                }
            }
        } else {
            return 0
        }
    }
    
    func getIphoneSizeScreen() -> String{
        return Device.CURRENT_SIZE
    }
    
    func getOffsetOfDay() -> CGFloat{
        var dayValueOffset = 0
        let iPhoneSizeScreen = getIphoneSizeScreen()
        if debug {
            print("getDayOfWeek: \(getDayOfWeek())")
        }
        let currentLang = Device.CURRENT_LANGUAGE
        if (currentLang == "en"){
            if (iPhoneSizeScreen == "iPhone6"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Public.Monday_iPhone6
                case "Tuesday":
                    dayValueOffset = Public.Tuesday_iPhone6
                case "Wednesday":
                    dayValueOffset = Public.Wednesday_iPhone6
                case "Thursday":
                    dayValueOffset = Public.Thursday_iPhone6
                case "Friday":
                    dayValueOffset = Public.Friday_iPhone6
                default:
                    dayValueOffset = Public.Weekend_iPhone6
                }
            } else if (iPhoneSizeScreen == "iPhone6+"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Public.Monday_iPhone6Plus
                case "Tuesday":
                    dayValueOffset = Public.Tuesday_iPhone6Plus
                case "Wednesday":
                    dayValueOffset = Public.Wednesday_iPhone6Plus
                case "Thursday":
                    dayValueOffset = Public.Thursday_iPhone6Plus
                case "Friday":
                    dayValueOffset = Public.Friday_iPhone6Plus
                default:
                    dayValueOffset = Public.Weekend_iPhone6Plus
                }
                
            } else if (iPhoneSizeScreen == "iPhone5"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Public.Monday_iPhone5
                case "Tuesday":
                    dayValueOffset = Public.Tuesday_iPhone5
                case "Wednesday":
                    dayValueOffset = Public.Wednesday_iPhone5
                case "Thursday":
                    dayValueOffset = Public.Thursday_iPhone5
                case "Friday":
                    dayValueOffset = Public.Friday_iPhone5
                default:
                    dayValueOffset = Public.Weekend_iPhone5
                }
            } else if (iPhoneSizeScreen == "iPhone4"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Public.Monday_iPhone4
                case "Tuesday":
                    dayValueOffset = Public.Tuesday_iPhone4
                case "Wednesday":
                    dayValueOffset = Public.Wednesday_iPhone4
                case "Thursday":
                    dayValueOffset = Public.Thursday_iPhone4
                case "Friday":
                    dayValueOffset = Public.Friday_iPhone4
                default:
                    dayValueOffset = Public.Weekend_iPhone4
                }
            }
        } else {
            if (iPhoneSizeScreen == "iPhone6"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Public.Monday_iPhone6
                case "mardi":
                    dayValueOffset = Public.Tuesday_iPhone6
                case "mercredi":
                    dayValueOffset = Public.Wednesday_iPhone6
                case "jeudi":
                    dayValueOffset = Public.Thursday_iPhone6
                case "vendredi":
                    dayValueOffset = Public.Friday_iPhone6
                default:
                    dayValueOffset = Public.Weekend_iPhone6
                }
            } else if (iPhoneSizeScreen == "iPhone6+"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Public.Monday_iPhone6Plus
                case "mardi":
                    dayValueOffset = Public.Tuesday_iPhone6Plus
                case "mercredi":
                    dayValueOffset = Public.Wednesday_iPhone6Plus
                case "jeudi":
                    dayValueOffset = Public.Thursday_iPhone6Plus
                case "vendredi":
                    dayValueOffset = Public.Friday_iPhone6Plus
                default:
                    dayValueOffset = Public.Weekend_iPhone6Plus
                }
                
            } else if (iPhoneSizeScreen == "iPhone5"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Public.Monday_iPhone5
                case "mardi":
                    dayValueOffset = Public.Tuesday_iPhone5
                case "mercredi":
                    dayValueOffset = Public.Wednesday_iPhone5
                case "jeudi":
                    dayValueOffset = Public.Thursday_iPhone5
                case "vendredi":
                    dayValueOffset = Public.Friday_iPhone5
                default:
                    dayValueOffset = Public.Weekend_iPhone5
                }
            } else if (iPhoneSizeScreen == "iPhone4"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Public.Monday_iPhone4
                case "mardi":
                    dayValueOffset = Public.Tuesday_iPhone4
                case "mercredi":
                    dayValueOffset = Public.Wednesday_iPhone4
                case "jeudi":
                    dayValueOffset = Public.Thursday_iPhone4
                case "vendredi":
                    dayValueOffset = Public.Friday_iPhone4
                default:
                    dayValueOffset = Public.Weekend_iPhone4
                }
            }
        }
        if debug {
            print("current size: \(Device.CURRENT_SIZE)")
        }
        return CGFloat(dayValueOffset)
    }
    
    func getDayOfWeekSimple() -> String {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.stringFromDate(date)
        return dayOfWeekString
    }
    
    func getDayOfWeek() -> String{
        var date = NSDate()
        if shouldGoTomorrow() && getDayOfWeekSimple() != "Sunday" && getDayOfWeekSimple() != "dimanche" {
            date = date.addDays(1)
        }
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.stringFromDate(date)
        
        return dayOfWeekString
    }
    
    private func getHourString() -> String {
        let date = NSDate();
        let formatter = NSDateFormatter();
        formatter.dateFormat = "h:mm a";
        let defaultTimeZoneStr = formatter.stringFromDate(date);
        return defaultTimeZoneStr
    }
    
    private func shouldGoTomorrow() -> Bool {
        let currentHourString = getHourString()
        print("current hour string: \(currentHourString)")
        let hourStringToCompare = "07:00 PM"
        let formatter = NSDateFormatter();
        formatter.dateFormat = "h:mm a";
        let currentDate = formatter.dateFromString(currentHourString)
        let dateToCompare = formatter.dateFromString(hourStringToCompare)
        if currentDate!.isGreaterThanDate(dateToCompare!) {
            return true
        } else {
            return false
        }
    }
    
    func segueToSettingsIfNeeded(){
        if !getBeenToSettingsOnce() {
            self.performSegueWithIdentifier(Public.segueBeenToSettingsOnce, sender: self)
        }
    }
    
    
    func getUrlPlanning(weekNumber: Int) -> String {
        let IDWebPlanning = getIDPlanningExpress()
        if IDWebPlanning == "" || IDWebPlanning == Public.noGroupINSA {
            return Public.noGroupINSA
        } else {
            if debug {
                print("https://www.etud.insa-toulouse.fr/planning/index.php?gid=\(IDWebPlanning)&wid=\(weekNumber)&platform=ios")
            }
            return "https://www.etud.insa-toulouse.fr/planning/index.php?gid=\(IDWebPlanning)&wid=\(weekNumber)&platform=ios"
        }
    }
    
    func getWeekNumber() -> Int {
        let calender = NSCalendar.currentCalendar()
        let dateComponent = calender.component(NSCalendarUnit.WeekOfYear, fromDate: NSDate())
        print("date: \(NSDate())")
        let dayOfWeek = getDayOfWeek()
        if debug {
            print("date component: \(dateComponent)")
            print("dayOfWeek = \(dayOfWeek)")
        }
        if (dayOfWeek == "Saturday" || dayOfWeek == "samedi" || dayOfWeek == "Sunday" || dayOfWeek == "dimanche"){
            return dateComponent + 1
        } else {
            return dateComponent
        }
    }
    
    func getWeekNumberForZoom() -> Int {
        let calender = NSCalendar.currentCalendar()
        let dateComponent = calender.component(NSCalendarUnit.WeekOfYear, fromDate: NSDate())
        return dateComponent
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    // MARK: Network
    
    @IBAction func nextWeekButtonAction(sender: AnyObject) {
        weekNumberToday += 1
        AmITheCurrentWeek = false
        if let url = NSURL(string: getUrlPlanning(weekNumberToday)) {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        } else {
            let url = NSURL(string:"https://www.etud.insa-toulouse.fr/planning/index.php")
            let request = NSURLRequest(URL: url!)
            webView.loadRequest(request)
        }
    }
    
    @IBAction func lastWeekButtonAction(sender: AnyObject) {
        weekNumberToday -= 1
        AmITheCurrentWeek = false
        if let url = NSURL(string: getUrlPlanning(weekNumberToday)) {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        } else {
            let url = NSURL(string:"https://www.etud.insa-toulouse.fr/planning/index.php")
            let request = NSURLRequest(URL: url!)
            webView.loadRequest(request)
        }
    }
    
    @IBAction func todayWeekButtonAction(sender: AnyObject) {
        AmITheCurrentWeek = true
        weekNumberToday = getWeekNumber()
        if let url = NSURL(string: getUrlPlanning(weekNumberToday)) {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        } else {
            let url = NSURL(string:"https://www.etud.insa-toulouse.fr/planning/index.php")
            let request = NSURLRequest(URL: url!)
            webView.loadRequest(request)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Public.segueFromPlanningToSettings {
            let settingsVC = segue.destinationViewController as! SettingsTableViewController
            settingsVC.comeFromWebPlanningBecauseNoGroupSelected = true
        }
    }
    
}
