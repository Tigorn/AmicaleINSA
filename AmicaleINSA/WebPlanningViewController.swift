//
//  WebPlanningViewController.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 29/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import UIKit
import SwiftSpinner

class WebPlanningViewController: UIViewController, UIWebViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var menuButton:UIBarButtonItem!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var ActualBarButtonItem: UIBarButtonItem!
    var weekNumberToday : Int = 0
    var debug = false
    let offsetScroll = CGFloat(190)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.view.addGestureRecognizer(self.revealViewController().tapGestureRecognizer())
        }
        
        self.navigationController?.navigationBar.translucent = false
        
        // set delegate
        self.webView.delegate = self
        self.webView.scrollView.delegate = self
        
        ActualBarButtonItem.title = "4-Info-TD-B"
        weekNumberToday = getWeekNumber()
        let url = NSURL(string: getUrlPlanning(weekNumberToday))
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
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
        if (debug) {
            print("[WebPlanningViewController][webViewDidFinishLoad] I stop loading my page")
        }
        SwiftSpinner.hide()
        
        self.webView.scrollView.setZoomScale(getZoomValue(), animated: true)
        print("getOffSet: \(getOffsetOfDay())")
        self.webView.scrollView.contentOffset = CGPointMake(getOffsetOfDay(), 0)
        
    }
    
    func getZoomValue() -> CGFloat {
        let currentLang = Device.CURRENT_LANGUAGE
        if (currentLang == "en"){
            if (getDayOfWeek() == "Saturday") || (getDayOfWeek() == "Sunday"){
                return 0
            } else {
                return 3
            }
        } else {
            if (getDayOfWeek() == "samedi") || (getDayOfWeek() == "dimanche"){
                return 0
            } else {
                return 3
            }
        }
    }
    
    func getIphoneSizeScreen() -> String{
        return Device.CURRENT_SIZE
    }
    
    func getOffsetOfDay() -> CGFloat{
        var dayValueOffset = 0
        let iPhoneSizeScreen = getIphoneSizeScreen()
        print("getDayOfWeek: \(getDayOfWeek())")
        let currentLang = Device.CURRENT_LANGUAGE
        if (currentLang == "en"){
            if (iPhoneSizeScreen == "iPhone6"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Storyboard.Monday_iPhone6
                case "Tuesday":
                    dayValueOffset = Storyboard.Tuesday_iPhone6
                case "Wednesday":
                    dayValueOffset = Storyboard.Wednesday_iPhone6
                case "Thursday":
                    dayValueOffset = Storyboard.Thursday_iPhone6
                case "Friday":
                    dayValueOffset = Storyboard.Friday_iPhone6
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone6
                }
            } else if (iPhoneSizeScreen == "iPhone6+"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Storyboard.Monday_iPhone6Plus
                case "Tuesday":
                    dayValueOffset = Storyboard.Tuesday_iPhone6Plus
                case "Wednesday":
                    dayValueOffset = Storyboard.Wednesday_iPhone6Plus
                case "Thursday":
                    dayValueOffset = Storyboard.Thursday_iPhone6Plus
                case "Friday":
                    dayValueOffset = Storyboard.Friday_iPhone6Plus
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone6Plus
                }
                
            } else if (iPhoneSizeScreen == "iPhone5"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Storyboard.Monday_iPhone5
                case "Tuesday":
                    dayValueOffset = Storyboard.Tuesday_iPhone5
                case "Wednesday":
                    dayValueOffset = Storyboard.Wednesday_iPhone5
                case "Thursday":
                    dayValueOffset = Storyboard.Thursday_iPhone5
                case "Friday":
                    dayValueOffset = Storyboard.Friday_iPhone5
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone5
                }
            } else if (iPhoneSizeScreen == "iPhone4"){
                switch getDayOfWeek() {
                case "Monday":
                    dayValueOffset = Storyboard.Monday_iPhone4
                case "Tuesday":
                    dayValueOffset = Storyboard.Tuesday_iPhone4
                case "Wednesday":
                    dayValueOffset = Storyboard.Wednesday_iPhone4
                case "Thursday":
                    dayValueOffset = Storyboard.Thursday_iPhone4
                case "Friday":
                    dayValueOffset = Storyboard.Friday_iPhone4
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone4
                }
            }
        } else {
            if (iPhoneSizeScreen == "iPhone6"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Storyboard.Monday_iPhone6
                case "mardi":
                    dayValueOffset = Storyboard.Tuesday_iPhone6
                case "mercredi":
                    dayValueOffset = Storyboard.Wednesday_iPhone6
                case "jeudi":
                    dayValueOffset = Storyboard.Thursday_iPhone6
                case "vendredi":
                    dayValueOffset = Storyboard.Friday_iPhone6
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone6
                }
            } else if (iPhoneSizeScreen == "iPhone6+"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Storyboard.Monday_iPhone6Plus
                case "mardi":
                    dayValueOffset = Storyboard.Tuesday_iPhone6Plus
                case "mercredi":
                    dayValueOffset = Storyboard.Wednesday_iPhone6Plus
                case "jeudi":
                    dayValueOffset = Storyboard.Thursday_iPhone6Plus
                case "vendredi":
                    dayValueOffset = Storyboard.Friday_iPhone6Plus
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone6Plus
                }
                
            } else if (iPhoneSizeScreen == "iPhone5"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Storyboard.Monday_iPhone5
                case "mardi":
                    dayValueOffset = Storyboard.Tuesday_iPhone5
                case "mercredi":
                    dayValueOffset = Storyboard.Wednesday_iPhone5
                case "jeudi":
                    dayValueOffset = Storyboard.Thursday_iPhone5
                case "vendredi":
                    dayValueOffset = Storyboard.Friday_iPhone5
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone5
                }
            } else if (iPhoneSizeScreen == "iPhone4"){
                switch getDayOfWeek() {
                case "lundi":
                    dayValueOffset = Storyboard.Monday_iPhone4
                case "mardi":
                    dayValueOffset = Storyboard.Tuesday_iPhone4
                case "mercredi":
                    dayValueOffset = Storyboard.Wednesday_iPhone4
                case "jeudi":
                    dayValueOffset = Storyboard.Thursday_iPhone4
                case "vendredi":
                    dayValueOffset = Storyboard.Friday_iPhone4
                default:
                    dayValueOffset = Storyboard.Weekend_iPhone4
                }
            }
        }
        print("current size: \(Device.CURRENT_SIZE)")
        return CGFloat(dayValueOffset)
    }
    
    
    func getDayOfWeek() -> String{
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEEE"
        let dayOfWeekString = dateFormatter.stringFromDate(date)
        return dayOfWeekString
    }
    
    
    
    func getUrlPlanning(weekNumber: Int) -> String {
        let IDWebPlanning = "1722+1723"
        print("https://www.etud.insa-toulouse.fr/planning/index.php?gid=\(IDWebPlanning)&wid=\(weekNumber)&platform=ios")
        return "https://www.etud.insa-toulouse.fr/planning/index.php?gid=\(IDWebPlanning)&wid=\(weekNumber)&platform=ios"
    }
    
    func getWeekNumber() -> Int {
        let calender = NSCalendar.currentCalendar()
        let dateComponent = calender.component(NSCalendarUnit.WeekOfYear, fromDate: NSDate())
        if (getDayOfWeek() == "Saturday" || getDayOfWeek() == "samedi" || getDayOfWeek() == "Sunday" || getDayOfWeek() == "dimanche"){
            return dateComponent + 1
        } else {
            return dateComponent
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    // MARK: Network
    
    @IBAction func nextWeekButtonAction(sender: AnyObject) {
        weekNumberToday++
        let url = NSURL(string: getUrlPlanning(weekNumberToday))
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }
    
    @IBAction func lastWeekButtonAction(sender: AnyObject) {
        weekNumberToday--
        let url = NSURL(string: getUrlPlanning(weekNumberToday))
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }
    
    @IBAction func todayWeekButtonAction(sender: AnyObject) {
        let url = NSURL(string: getUrlPlanning(getWeekNumber()))
        let request = NSURLRequest(URL: url!)
        weekNumberToday = getWeekNumber()
        webView.loadRequest(request)
    }
    
}
