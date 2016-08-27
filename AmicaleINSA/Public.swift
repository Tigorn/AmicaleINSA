//
//  Public.swift
//  AmicaleINSA
//
//  Created by Arthur Papailhau on 28/02/16.
//  Copyright © 2016 Arthur Papailhau. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SCLAlertView
import Alamofire
import Firebase

public struct Public {
    
    // Chat
    static let usernameChat = "usernameChat"
    static let usernameChatRegistred = "usernameChatRegistred"
    
    // Settings
    static let profilePictureIsSet = "profilePictureIsSet"
    static let profilePicture = "profilePicture"
    static let beenToSettingsOnce = "beenToSettingsOnce"
    static let segueBeenToSettingsOnce = "showSettingsFirstConnexion"
    
    // Webview offset
    static let Monday_iPhone4 = 0
    static let Tuesday_iPhone4 = 160
    static let Wednesday_iPhone4 = 350
    static let Thursday_iPhone4 = 530
    static let Friday_iPhone4 = 700
    static let Weekend_iPhone4 = 0
    
    static let Monday_iPhone5 = 0
    static let Tuesday_iPhone5 = 165
    static let Wednesday_iPhone5 = 350
    static let Thursday_iPhone5 = 530
    static let Friday_iPhone5 = 700
    static let Weekend_iPhone5 = 0
    
    static let Monday_iPhone6 = 0
    static let Tuesday_iPhone6 = 190
    static let Wednesday_iPhone6 = 410
    static let Thursday_iPhone6 = 625
    static let Friday_iPhone6 = 850
    static let Weekend_iPhone6 = 0
    
    static let Monday_iPhone6Plus = 0
    static let Tuesday_iPhone6Plus = 210
    static let Wednesday_iPhone6Plus = 445
    static let Thursday_iPhone6Plus = 685
    static let Friday_iPhone6Plus = 860
    static let Weekend_iPhone6Plus = 0
    
    static let SERVER_ADDR = "http://92.222.86.168/"
    static let urlProxyWash = "http://www.proxiwash.com/weblaverie/ma-laverie-2?s=cf4f39&16d33a57b3fb9a05d4da88969c71de74=1"
    static let urlWeatherToulouse = "https://api.forecast.io/forecast/5877c3394948db03ae04471da46fde3c/43.5722715,1.4687831"
    static let urlWashINSAAPI = "\(Public.SERVER_ADDR)washinsa/json"
    static let urlLocalsINSAAPI = "\(Public.SERVER_ADDR)locals/json"
    static let urlVersionsNotAllowed = "\(Public.SERVER_ADDR)versions/json"
    
    // Planning Express
    static let idPlanningExpress = "idPlanningExpress"
    static let yearSpeGroupPlanningExpress = "yearSpeGroupPlanningExpress"
    static let rowPickerViewSettings = "rowPickerViewSettings"
    
    // Weather
    static let temperatureNSUserDefaults = "temperatureWeather"
    
    // Push Notifications
    static let isRegisterForPushNotifications = "isRegisterForPushNotifications"
    static let userWantsToBeRegistreredForPushNotifications = "userWantsToBeRegistreredForPushNotifications"
    static let userDeclinedToBeRegisteredForPushNotifications = "userDeclinedToBeRegisteredForPushNotifications"
    static let userAnsweredForPushNotifications = "userAnsweredForPushNotifications"
    
    static let titleAlertPushNotification = "Push Notifications"
    static let subtitleAlertPushNotification = "Accepte les notifications pour bénéficier des dernières infos du campus en temps réel !"
    
    // App versions not Allowed
    static let titleAlertVersionNotAllowed = "Attention !"
    static let subtitleAlertVersionNotAllowed = "La version actuelle de l'application risque de ne pas fonctionner correctement, veuillez la mettre à jour."
}

/*
 removeNSUserDefault
 */

public func removeNSUserDefault(){
    for key in NSUserDefaults.standardUserDefaults().dictionaryRepresentation().keys {
        print(key)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(key)
    }
    NSUserDefaults.standardUserDefaults().synchronize()
}

/*
 Function called when app launched
 */

public func initApp() {
    if (NSUserDefaults.standardUserDefaults().boolForKey(Public.usernameChatRegistred) ==  false) {
        let usernameChat = "invite\(Int(arc4random_uniform(UInt32(2500))))"
        NSUserDefaults.standardUserDefaults().setObject(usernameChat, forKey: Public.usernameChat)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.usernameChatRegistred)
    }
    setTemperature()
    loadVersionsNumberNotAllowed()
    FIRAuth.auth()!.signInAnonymouslyWithCompletion() { (user, error) in
        if let error = error {
            print("Sign in failed:", error.localizedDescription)
        }
    }
}

/*
 Settings
 */

public func setBeenToSettingsOnce(){
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.beenToSettingsOnce)
}

public func getBeenToSettingsOnce() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.beenToSettingsOnce)
}

/*
 username getter/setter
 */

public func setUsernameChat(username: String) {
    NSUserDefaults.standardUserDefaults().setObject(username, forKey: Public.usernameChat)
}

public func getUsernameChat() -> String {
    if let username = NSUserDefaults.standardUserDefaults().stringForKey(Public.usernameChat) {
        return username
    } else {
        var randomNumber = Int(arc4random_uniform(UInt32(10000)))
        if randomNumber % 2 == 1 {
            randomNumber += 1
        }
        return "invite\(randomNumber)"
    }
}

/*
 Planning Express
 */

private func _returnDefaultIDPlanningExpress() -> String {
    return "394"
}

private func _returnDefaultYearSpeGroupPlanningExpress() -> String {
    return "1A - A"
}

public func getIDPlanningExpress() -> String {
    if let idPlanningExpress = NSUserDefaults.standardUserDefaults().stringForKey(Public.idPlanningExpress) {
        return idPlanningExpress
    } else {
        return _returnDefaultIDPlanningExpress()
    }
}

public func setIDPlanningExpress(id: String) {
    NSUserDefaults.standardUserDefaults().setObject(id, forKey: Public.idPlanningExpress)
}

public func getYearSpeGroupPlanningExpress() -> String {
    if let yearSpeGroup = NSUserDefaults.standardUserDefaults().stringForKey(Public.yearSpeGroupPlanningExpress) {
        return yearSpeGroup
    } else {
        return _returnDefaultYearSpeGroupPlanningExpress()
    }
}

public func setYearSpeGroupPlanningExpress(yearSpeGroup:String){
    NSUserDefaults.standardUserDefaults().setObject(yearSpeGroup, forKey: Public.yearSpeGroupPlanningExpress)
}

/*
 profile picture getter/setter
 */

public func setProfilPicture(image : UIImage){
    print("setProfilePicture in")
    NSUserDefaults.standardUserDefaults().setObject(UIImagePNGRepresentation(image), forKey: Public.profilePicture)
    print("setProfilePicture in 2")
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.profilePictureIsSet)
    print("setProfilePicture in 3")
    NSUserDefaults.standardUserDefaults().synchronize()
    print("setProfilePicture out")
}

public func getProfilPicture() -> UIImage {
    let isProfilePictureIsSet = NSUserDefaults.standardUserDefaults().boolForKey(Public.profilePictureIsSet)
    if isProfilePictureIsSet{
        if let  imageData = NSUserDefaults.standardUserDefaults().objectForKey(Public.profilePicture) as? NSData {
            let profilePicture = UIImage(data: imageData)
            return profilePicture!
        } else{
            return  UIImage(named: "defaultPic")! }
    } else {
        return UIImage(named: "defaultPic")!
    }
}

/*
 Weather
 */

public func getTemperature() -> String {
    if let temperature = NSUserDefaults.standardUserDefaults().stringForKey(Public.temperatureNSUserDefaults) {
        return "\(temperature) °C"
    } else {
        return ""
    }
}

private func setTemperature(){
    let url = Public.urlWeatherToulouse
    let urlNSUrl = NSURL(string: url)
    let qos = Int(QOS_CLASS_USER_INITIATED.rawValue) // qos = quality of service (if it's slow, important...)
    dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
        if  let data = NSData(contentsOfURL: urlNSUrl!) {
            dispatch_async(dispatch_get_main_queue(), {
                let json = JSON(data: data)
                if let temperature = json["currently"]["temperature"].float{
                    let temperatureCelsius = (temperature-32)/1.8
                    let temperatureCelsiusString = String(format: "%.1f", temperatureCelsius)
                    NSUserDefaults.standardUserDefaults().setObject(temperatureCelsiusString, forKey: Public.temperatureNSUserDefaults)
                }
                NSUserDefaults.standardUserDefaults().synchronize()
                }
            )
        }
    }
}

/*
 Push Notifications
 Si l'utilisateur n'a jamais rien dit, il faut lui demander si il veut accepter les push notifications
 Si l'utilisateur a dékà accepté, on dit rien
 Si l'utilisateur a dit non, on dit rien
 */

private func getUserAnsweredForPushNotifications() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.userAnsweredForPushNotifications)
}

private func setUserAnsweredForPushNotifications() {
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.userAnsweredForPushNotifications)
}

private func getUserWantsToBeRegistreredForPushNotifications() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.userWantsToBeRegistreredForPushNotifications)
}

private func getUserDeclinedToBeRegisteredForPushNotifications() -> Bool {
    return NSUserDefaults.standardUserDefaults().boolForKey(Public.userDeclinedToBeRegisteredForPushNotifications)
}

public func setUserDeclinedToBeRegisteredForPushNotifications() {
    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Public.userDeclinedToBeRegisteredForPushNotifications)
}

private func getUserAlreadyRegisteredForPushNotifications() -> Bool {
    let notificationType = UIApplication.sharedApplication().currentUserNotificationSettings()!.types
    if notificationType == UIUserNotificationType.None {
        return false
    }else{
        return true
    }
}

/*
 TODO: set userDeclined... to true if user declines to be registered for Push Notification
 */
private func getShowAlertForPermissionPushNotifications() -> Bool {
    let userDeclinedToBeRegisteredForPushNotifications = getUserDeclinedToBeRegisteredForPushNotifications()
    let userAlreadyRegisteredForPushNotifications = getUserAlreadyRegisteredForPushNotifications()
    let userAnsweredForPushNotifications = getUserAnsweredForPushNotifications()
    
    if userDeclinedToBeRegisteredForPushNotifications {
        return false
    } else if userAlreadyRegisteredForPushNotifications {
        return false
    } else if userAnsweredForPushNotifications {
        return false
    } else {
        return true
    }
}


public func registerForNotificationsAndEnterApp(controller: UIViewController) {
    let showAlert = getShowAlertForPermissionPushNotifications()
    if showAlert {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        alert.addButton("Compris !") {
            setUserAnsweredForPushNotifications()
            let application = UIApplication.sharedApplication()
            print("J'affiche l'alert qui va demander de recevoir des notifications")
            let userNotificationTypes: UIUserNotificationType = [.Alert, .Badge, .Sound]
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        alert.showInfo(Public.titleAlertPushNotification, subTitle: Public.subtitleAlertPushNotification)
    }
}

public func sendLocalNotificationWashingMachine(time: Int, numeroMachine: Int, numberOfMinutesBeforeTheEndOfTheMachine: Int){
    print("An alert will be sent in \(time-numberOfMinutesBeforeTheEndOfTheMachine) minutes")
    let timeFireDate = Double((time-numberOfMinutesBeforeTheEndOfTheMachine)*60)
    var alertBody = "Vite, ton linge est prêt !!"
    if numberOfMinutesBeforeTheEndOfTheMachine == 5 {
        alertBody = "Ton linge sera prêt dans 5 minutes !"
    } else if numberOfMinutesBeforeTheEndOfTheMachine == 10 {
        alertBody = "Commence à te préparer, tu dois être à la laverie dans 10 minutes !"
    }
    let notification = UILocalNotification()
    notification.fireDate = NSDate(timeIntervalSinceNow: timeFireDate)
    notification.alertBody = alertBody
    notification.alertAction = "récupérer ton linge !"
    notification.userInfo = ["numero_machine": numeroMachine, "alert": true]
    notification.soundName = UILocalNotificationDefaultSoundName
    UIApplication.sharedApplication().scheduleLocalNotification(notification)
}

public func setLocalNotificationWithoutAlertWashingMachine(time: Int, numeroMachine: Int) {
    print("Set a local notification without alert, in \(time) minutes")
    let notification = UILocalNotification()
    notification.fireDate = NSDate(timeIntervalSinceNow: Double(time*60))
    notification.alertBody = nil
    notification.alertAction = nil
    notification.userInfo = ["numero_machine": numeroMachine, "alert": false]
    UIApplication.sharedApplication().scheduleLocalNotification(notification)
}

public func getVersionNumberApp() -> String {
    return NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
}

public func checkIfVersionNumberIsAllowed(versionsNumberNotAllowed: [String]) -> Bool {
    let versionNumberApp = getVersionNumberApp()
    if versionsNumberNotAllowed.contains(versionNumberApp) {
        return false
    } else {
        return true
    }
}

public func alertViewApplicationTooOld(message : String) {
    let appearance = SCLAlertView.SCLAppearance(
        showCloseButton: false
    )
    let alert = SCLAlertView(appearance: appearance)
    alert.addButton("Compris !"){
        
    }
    alert.showInfo(Public.titleAlertVersionNotAllowed, subTitle: message)
}

public func loadVersionsNotAllowedFromServer() {
    var msg = ""
    let url = Public.urlVersionsNotAllowed
    Alamofire.request(.GET, url).validate().responseJSON { response in
        switch response.result {
        case .Success:
            if let value = response.result.value {
                let json_full = JSON(value)
                let json = json_full["json"]
                if let messageVersionNotAllowed = json["iOS"]["message"].string {
                    msg = messageVersionNotAllowed
                }
                let arrayVersionNotAllowedJSON = json["iOS"]["versionsNotAllowed"]
                var arrayVersionNotAllowedString:[String] = []
                for version in arrayVersionNotAllowedJSON {
                    arrayVersionNotAllowedString.append(String(version.1))
                }
                if !checkIfVersionNumberIsAllowed(arrayVersionNotAllowedString) {
                    alertViewApplicationTooOld(msg)
                }
            }
        case .Failure(let error):
            print("Error: \(error)")
        }
    }
}

public func loadVersionsNumberNotAllowed() {
    loadVersionsNotAllowedFromServer()
}

public func getYearsINSAPlanning() -> [(String, String)] {
    return [("1A - A", "394"),
            ("1A - B", "396"),
            ("1A - C", "357"),
            ("1A - D", "41"),
            ("1A - E", "356"),
            ("1A - F", "223"),
            ("1A - FAS", "218"),
            ("1A - G", "43"),
            ("1A - H", "360"),
            ("1A - J", "353"),
            ("1A - K", "1536"),
            ("1A - M", "359"),
            ("1A - N", "363"),
            ("1A - Z", "45+362"),
            ("1A - IBERINSA", "365+681"),
            ("2-IC - A", "224"),
            ("2-IC - B", "270"),
            ("2-IC - C", "435"),
            ("2-IC - D", "225"),
            ("2-IC - E", "56"),
            ("2-IC - FAS", "1489"),
            ("2-ICBE - A", "211+213"),
            ("2-ICBE - B", "214+219"),
            ("2-ICBE - C", "243+249"),
            ("2-IMACS - A", "1024+1549"),
            ("2-IMACS - B", "1025+1550"),
            ("2-IMACS - C", "1022+1551"),
            ("2-IMACS - D", "534+535"),
            ("2-MIC - A", "1027"),
            ("2-MIC - B", "1030"),
            ("2-MIC - C", "1031"),
            ("2-MIC - D", "1028"),
            ("3-IC - A", "1321+1322"),
            ("3-IC - B", "1324+1325+1037"),
            ("3-IC - C", "1327+1328"),
            ("3-IC - D", "1330+1331"),
            ("3-IC - E", "1335+1336"),
            ("3-IC - F", "1339+1340"),
            ("3-IC - G", "1459+1457"),
            ("3-AGC", "9"),
            ("3-IMACS - A", "1170+1171"),
            ("3-IMACS - B", "1173+1174"),
            ("3-IMACS - C", "1176+1177"),
            ("3-IMACS - D", "1179+1180"),
            ("3-IMACS - E", "1494-1627"),
            ("3-MIC - A", "528+531"),
            ("3-MIC - B", "858+531"),
            ("3-MIC - C", "1135+1164"),
            ("3-MIC - D", "1166+1167"),
            ("3-MIC - E", "498+752"),
            ("3-MIC - OP", "1356+1359+1775+1776"),
            ("3-ICBE - A", "151"),
            ("3-ICBE - B", "441"),
            ("3-ICBE - C", "1109"),
            ("3-ICBE - D", "486"),
            ("4-GB - A", "328"),
            ("4-GB - B", "294"),
            ("4-GC - A", "103"),
            ("4-GC - B", "11+810"),
            ("4-GC - C", "306"),
            ("4-AGC", "194"),
            ("4-AE-TP - SE-1", "1736"),
            ("4-AE-TP - SE-2", "1738"),
            ("4-AE-TP - SE-3", "1739"),
            ("4-AE-TP - SE-4", "143"),
            ("4-AE-TP - IS-1", "1740"),
            ("4-GM-TP - IS-1", "1741"),
            ("4-GM-TP - IS-2", "1742"),
            ("4-IR-I - A", "1720+1721"),
            ("4-IR-I - B", "1722+1723"),
            ("4-IR-RT - A", "1724+1725"),
            
            ("4-GM-MO - MN", "649"),
            ("4-GM-MO - TA", "659"),
            ("4-GM-MO - UGV", "675"),
            ("4-GM - TPgr1", "1715"),
            ("4-GM - TPgr2", "1716"),
            ("4-GM - TPgr3", "1727"),
            ("4-GM - TPgr4", "1728"),
            ("4-GM - TPgr5", "1729"),
            ("4-GM - TPgr6", "914"),
            ("4-GM - gr1", "376"),
            ("4-GM - gr2", "378"),
            ("4-GM - gr3", "59"),
            ("4-GMM - MMN", "117"),
            ("4-GMM - MMS", "118"),
            ("4-GP - 1", "205+1337"),
            ("4-GP - 2", "274+1801"),
            ("4-GP - 3", "148+283"),
            ("4-GPE - G1", "631"),
            ("4-GPE - G2", "632"),
            ("4-GPE-TP - G1", "782"),
            ("4-GPE-TP - G2", "783"),
            ("4-GPE-TP - G3", "806"),
            ("4-GPE-TP - G4", "786"),
    ]
}

public func stringNotWhiteSpaceAndNotEmpty(str: String) -> Bool {
    let whitespaceSet = NSCharacterSet.whitespaceCharacterSet()
    if str.characters.count > 0 && str.stringByTrimmingCharactersInSet(whitespaceSet) != "" {
        return true
    }
    return false
}

